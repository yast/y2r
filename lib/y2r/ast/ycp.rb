# encoding: utf-8

require "ostruct"

module Y2R
  module AST
    # Classes in this module represent YCP AST nodes. Their main taks is to
    # compile themselves into Ruby AST nodes using the |compile| methods and its
    # siblings (|compile_as_block|, etc.).
    #
    # The structure of the AST is heavily influenced by the structure of XML
    # emitted by ycpc -x.
    module YCP
      # Compilation context passed to nodes' |compile| method. It mainly tracks
      # the scope we're in and contains related helper methods.
      class Context
        attr_accessor :blocks, :export_private

        def initialize(attrs = {})
          @blocks          = attrs[:blocks] || []
          @export_private  = attrs[:export_private] || false
          @as_include_file = attrs[:as_include_file] || false
        end

        def in?(klass)
          @blocks.find { |b| b.is_a?(klass) } ? true : false
        end

        def innermost(*klasses)
          @blocks.reverse.find { |b| klasses.any? { |k| b.is_a?(k) } }
        end

        def inside(block)
          yield Context.new(
            :blocks          => @blocks + [block],
            :export_private  => @export_private,
            :as_include_file => @as_include_file
          )
        end

        def module_name
          @blocks.first.name
        end

        def locals
          index = @blocks.index(&:creates_local_scope?) || @blocks.length
          @blocks[index..-1].map { |b| b.symbols.map(&:name) }.flatten
        end

        def globals
          index = @blocks.index(&:creates_local_scope?) || @blocks.length
          @blocks[0..index].map { |b| b.symbols.map(&:name) }.flatten
        end

        def symbol_for(name)
          symbols = @blocks.map { |b| b.symbols }.flatten
          symbols.reverse.find { |s| s.name == name }
        end
      end

      # Represents a YCP type.
      class Type
        attr_reader :type

        def initialize(type)
          @type = type
        end

        def ==(other)
          other.instance_of?(Type) && other.type == @type
        end

        def to_s
          @type
        end

        def reference?
          @type =~ /&$/
        end

        def no_const
          @type =~ /^const / ? Type.new(@type.sub(/^const /, "")) : self
        end

        def arg_types
          types = []
          type = ""
          nesting_level = 0

          in_parens = @type.sub(/^[^(]*\((.*)\)[^)]*$/, '\1')
          in_parens.each_char do |ch|
            case ch
              when ","
                if nesting_level == 0
                  types << type
                  type = ""
                else
                  type += ch
                end

              when "(", "<"
                nesting_level += 1
                type += ch

              when ")", ">"
                nesting_level -= 1
                type += ch

              else
                type += ch
            end
          end
          types << type unless type.empty?

          types.map { |t| Type.new(t.strip) }
        end

        BOOLEAN = Type.new("boolean")
        INTEGER = Type.new("integer")
        SYMBOL  = Type.new("symbol")
      end

      # Contains utility functions related to Ruby variables.
      module RubyVar
        # Taken from Ruby's parse.y (for 1.9.3).
        RUBY_KEYWORDS = [
          "BEGIN",
          "END",
          "__ENCODING__",
          "__FILE__",
          "__LINE__",
          "alias",
          "and",
          "begin",
          "break",
          "case",
          "class",
          "def",
          "defined",
          "do",
          "else",
          "elsif",
          "end",
          "ensure",
          "false",
          "for",
          "if",
          "in",
          "module",
          "next",
          "nil",
          "not",
          "or",
          "redo",
          "rescue",
          "retry",
          "return",
          "self",
          "super",
          "then",
          "true",
          "undef",
          "unless",
          "until",
          "when",
          "while",
          "yield"
        ]

        class << self
          # Escapes a YCP variable name so that it is a valid Ruby local
          # variable name.
          #
          # The escaping is constructed so that it can't create any collision
          # between names. More precisely, for any distinct strings passed to
          # this function the results will be also distinct.
          def escape_local(name)
            name.sub(/^(#{RUBY_KEYWORDS.join("|")}|[A-Z_].*)$/) { |s| "_#{s}" }
          end

          # Builds a Ruby AST node for a variable with given name in given
          # context, doing all necessary escaping, de-aliasing, etc.
          def for(ns, name, context, mode)
            # In the XML, all global module variable references are qualified
            # (e.g. "M::i"). This includes references to variables defined in
            # this module. All other variable references are unqualified (e.g
            # "i").
            if ns
              if ns == context.module_name
                Ruby::Variable.new(:name => "@#{name}")
              else
                Ruby::MethodCall.new(
                  :receiver => Ruby::Variable.new(:name => ns),
                  :name     => name,
                  :args     => [],
                  :block    => nil,
                  :parens   => true
                )
              end
            else
              is_local = context.locals.include?(name)
              variables = if is_local
                context.locals
              else
                context.globals
              end

              # If there already is a variable with given name (coming from some
              # parent scope), suffix the variable name with "2". If there are two
              # such variables, suffix the name with "3". And so on.
              #
              # The loop is needed because we need to do the same check and maybe
              # additional round(s) of suffixing also for suffixed variable names to
              # prevent conflicts.
              suffixed_name = name
              begin
                count = variables.select { |v| v == suffixed_name }.size
                suffixed_name = suffixed_name + count.to_s if count > 1
              end while count > 1

              variable_name = if is_local
                RubyVar.escape_local(suffixed_name)
              else
                "@#{suffixed_name}"
              end

              variable = Ruby::Variable.new(:name => variable_name)

              case mode
                when :in_code
                  symbol = context.symbol_for(name)
                  # The "symbol &&" part is needed only because of tests. The symbol
                  # should be always present in real-world situations.
                  if symbol && symbol.category == :reference
                    Ruby::MethodCall.new(
                      :receiver => variable,
                      :name     => "value",
                      :args     => [],
                      :block    => nil,
                      :parens   => true
                    )
                  else
                    variable
                  end

                when :in_arg
                  variable

                else
                  raise "Unknown mode: #{mode.inspect}."
              end
            end
          end
        end
      end

      class Node < OpenStruct
        def creates_local_scope?
          false
        end

        def compile_statements(statements, context)
          if statements
            statements.compile(context)
          else
            Ruby::Statements.new(:statements => [])
          end
        end

        def compile_statements_inside_block(statements, context)
          context.inside self do |inner_context|
            compile_statements(statements, inner_context)
          end
        end
      end

      # Sorted alphabetically.

      class Assign < Node
        def compile(context)
          Ruby::Assignment.new(
            :lhs => RubyVar.for(ns, name, context, :in_code),
            :rhs => child.compile(context)
          )
        end
      end

      class Bracket < Node
        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "assign",
            :args     => [
              entry.compile(context),
              arg.compile(context),
              rhs.compile(context),
            ],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class Break < Node
        def compile(context)
          case context.innermost(While, Do, Repeat, UnspecBlock)
            when While, Do, Repeat
              Ruby::Break.new
            when UnspecBlock
              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "raise",
                :args     => [Ruby::Variable.new(:name => "Break")],
                :block    => nil,
                :parens   => false
              )
            else
              raise "Misplaced \"break\" statement."
          end
        end
      end

      class Builtin < Node
        def compile(context)
          module_name = case ns
            when "SCR"
              "SCR"
            when "WFM"
              "WFM"
            when "float"
              "Builtins::Float"
            when "list"
              "Builtins::List"
            when "multiset"
              "Builtins::Multiset"
            else
              "Builtins"
          end

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => module_name),
            :name     => name,
            :args     => args.map { |a| a.compile(context) },
            :block    => block ? block.compile_as_block(context) : nil,
            :parens   => true
          )
        end
      end

      class Call < Node
        def compile(context)
          call = case category
            when :function
              if !ns && context.locals.include?(name)
                Ruby::MethodCall.new(
                  :receiver => RubyVar.for(nil, name, context, :in_code),
                  :name     => "call",
                  :args     => args.map { |a| a.compile(context) },
                  :block    => nil,
                  :parens   => true
                )
              else
                # In the XML, all module function calls are qualified (e.g.
                # "M::i"). This includes call to functions defined in this
                # module. The problem is that in generated Ruby code, the module
                # namespace may not exist yet (e.g. when the function is called
                # at module toplvel in YCP), so we have to omit it (which is OK,
                # because then the call will be invoked on |self|, whish is
                # always our module).
                fixed_ns = ns == context.module_name ? nil : ns
                receiver = if fixed_ns
                  Ruby::Variable.new(:name => fixed_ns)
                else
                  nil
                end

                Ruby::MethodCall.new(
                  :receiver => receiver,
                  :name     => name,
                  :args     => args.map { |a| a.compile(context) },
                  :block    => nil,
                  :parens   => true
                )
              end
            when :variable # function reference stored in variable
              Ruby::MethodCall.new(
                :receiver => RubyVar.for(ns, name, context, :in_code),
                :name     => "call",
                :args     => args.map { |a| a.compile(context) },
                :block    => nil,
                :parens   => true
              )
            else
              raise "Unknown call category: #{category.inspect}."
          end

          reference_args_with_types = args.zip(type.arg_types).select do |arg, type|
            type.reference?
          end

          if !reference_args_with_types.empty?
            setters = reference_args_with_types.map do |arg, type|
              arg.compile_as_setter(context)
            end
            getters = reference_args_with_types.map do |arg, type|
              arg.compile_as_getter(context)
            end
            result_var = Ruby::Variable.new(
              :name => RubyVar.escape_local("#{name}_result")
            )

            Ruby::Expressions.new(
              :expressions => [
                *setters,
                Ruby::Assignment.new(:lhs => result_var, :rhs => call),
                *getters,
                result_var
              ]
            )
          else
            call
          end
        end
      end

      class Case < Node
        def compile(context)
          if body.statements.last.is_a?(Break)
            # The following dance is here because we want ot keep the AST nodes
            # immutable and thus avoid modifying their data.

            body_without_break = body.dup
            body_without_break.statements = body.statements[0..-2]
          elsif body.statements.last.is_a?(Return)
            body_without_break = body
          else
            raise NotImplementedError,
                  "Case without a break or return encountered. These are not supported."
          end

          Ruby::When.new(
            :values => values.map { |v| v.compile(context) },
            :body   => body_without_break.compile(context)
          )
        end
      end

      class Compare < Node
        OPS_TO_METHODS = {
          "==" => "equal",
          "!=" => "not_equal",
          "<"  => "less_than",
          ">"  => "greater_than",
          "<=" => "less_or_equal",
          ">=" => "greater_or_equal"
        }

        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => OPS_TO_METHODS[op],
            :args     => [lhs.compile(context), rhs.compile(context)],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class Const < Node
        def compile(context)
          case type
            when :void
              Ruby::Literal.new(:value => nil)
            when :bool
              case value
                when "true"
                  Ruby::Literal.new(:value => true)
                when "false"
                  Ruby::Literal.new(:value => false)
                else
                  raise "Unknown boolean value: #{value.inspect}."
              end
            when :int
              Ruby::Literal.new(:value => value.to_i)
            when :float
              Ruby::Literal.new(:value => value.sub(/\.$/, ".0").to_f)
            when :symbol
              Ruby::Literal.new(:value => value.to_sym)
            when :string
              Ruby::Literal.new(:value => value)
            when :path
              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "path",
                :args     => [Ruby::Literal.new(:value => value)],
                :block    => nil,
                :parens   => true
              )
            else
              raise "Unknown const type: #{type.inspect}."
          end
        end
      end

      class Continue < Node
        def compile(context)
          Ruby::Next.new
        end
      end

      class Default < Node
        def compile(context)
          if body.statements.last.is_a?(Break)
            # The following dance is here because we want ot keep the AST nodes
            # immutable and thus avoid modifying their data.

            body_without_break = body.dup
            body_without_break.statements = body.statements[0..-2]
          else
            body_without_break = body
          end

          Ruby::Else.new(:body => body_without_break.compile(context))
        end
      end

      class DefBlock < Node
        def creates_local_scope?
          true
        end

        def compile(context)
          context.inside self do |inner_context|
            Ruby::Statements.new(
              :statements => statements.map { |s| s.compile(inner_context) }
            )
          end
        end
      end

      class Do < Node
        def symbols
          []
        end

        def compile(context)
          Ruby::While.new(
            :condition => self.while.compile(context),
            :body      => Ruby::Begin.new(
              :statements => compile_statements_inside_block(self.do, context)
            )
          )
        end
      end

      class Entry < Node
        def compile(context)
          RubyVar.for(ns, name, context, :in_code)
        end

        def compile_as_ref(context)
          Ruby::Variable.new(:name => "#{name}_ref")
        end
      end

      class FileBlock < Node
        def name
          nil
        end

        def compile(context)
          class_statements = []

          context.inside self do |inner_context|
            class_statements += build_main_def(inner_context)
            class_statements += build_other_defs(inner_context)
          end

          Ruby::Program.new(
            :statements => Ruby::Statements.new(
              :statements => [
                Ruby::Module.new(
                  :name       => "YCP",
                  :statements => Ruby::Module.new(
                    :name       => "Clients",
                    :statements => Ruby::Class.new(
                      :name       => class_name,
                      :superclass => Ruby::Variable.new(:name => "Client"),
                      :statements => Ruby::Statements.new(
                        :statements => class_statements
                      )
                    )
                  )
                ),
                Ruby::MethodCall.new(
                  :receiver => Ruby::MethodCall.new(
                    :receiver => Ruby::ConstAccess.new(
                      :receiver => Ruby::ConstAccess.new(
                        :receiver => Ruby::Variable.new(:name => "YCP"),
                        :name     => "Clients"
                      ),
                      :name     => class_name
                    ),
                    :name     => "new",
                    :args     => [],
                    :block    => nil,
                    :parens   => true
                  ),
                  :name     => "main",
                  :args     => [],
                  :block    => nil,
                  :parens   => true
                )
              ]
            ),
            :comment    => comment
          )
        end

        private

        def class_name
          client_name = File.basename(filename).sub(/\.[^.]*$/, "")
          client_name.
            gsub(/^./)     { |s| s.upcase    }.
            gsub(/[_.-]./) { |s| s[1].upcase } + "Client"
        end

        def fundef_statements
          statements.select { |s| s.is_a?(FunDef) }
        end

        def other_statements
          statements - fundef_statements
        end

        def build_main_def(context)
          if !other_statements.empty?
            main_statements = other_statements.map { |s| s.compile(context) }
            main_statements << Ruby::Literal.new(:value => nil)

            [
              Ruby::Def.new(
                :name       => "main",
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => main_statements
                )
              )
            ]
          else
            []
          end
        end

        def build_other_defs(context)
          fundef_statements.map { |t| t.compile(context) }
        end
      end

      class Filename < Node
        def compile(context)
          # Ignored because we don't care about filename information.
        end
      end

      class FunDef < Node
        def compile(context)
          statements = block.compile(context)

          context.inside block do |inner_context|
            statements.statements = args.select(&:needs_copy?).map do |arg|
              arg.compile_as_copy_arg_call(inner_context)
            end + statements.statements

            unless statements.statements.last.is_a? Ruby::Return
              statements.statements << Ruby::Literal.new(:value => nil)
            end

            if !context.in?(DefBlock)
              Ruby::Def.new(
                :name       => name,
                :args       => args.map { |a| a.compile(inner_context) },
                :statements => statements
              )
            else
              Ruby::Assignment.new(
                :lhs => RubyVar.for(nil, name, context, :in_code),
                :rhs => Ruby::MethodCall.new(
                  :receiver => nil,
                  :name     => "lambda",
                  :args     => [],
                  :block    => Ruby::Block.new(
                    :args       => args.map { |a| a.compile(inner_context) },
                    :statements => statements
                  ),
                  :parens   => true
                )
              )
            end
          end
        end
      end

      class If < Node
        def compile(context)
          then_compiled = compile_statements(self.then, context)
          else_compiled = if self.else
            compile_statements(self.else, context)
          else
            nil
          end

          Ruby::If.new(
            :condition => cond.compile(context),
            :then      => then_compiled,
            :else      => else_compiled
          )
        end
      end

      class Import < Node
        def compile(context)
          # Using any SCR or WFM function results in an auto-import. We ignore
          # these auto-imports becasue neither SCR nor WFM are real modules.
          return nil if name == "SCR" || name == "WFM"

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "YCP"),
            :name     => "import",
            :args     => [Ruby::Literal.new(:value => name)],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class Include < Node
        def compile(context)
          # Ignored because ycpc already included the file for us.
        end
      end

      class List < Node
        def compile(context)
          Ruby::Array.new(
            :elements => children.map { |ch| ch.compile(context) }
          )
        end
      end

      class Locale < Node
        def compile(context)
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "_",
            :args     => [Ruby::Literal.new(:value => text)],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class Map < Node
        def compile(context)
          Ruby::Hash.new(:entries => children.map { |ch| ch.compile(context) })
        end
      end

      class MapElement < Node
        def compile(context)
          Ruby::HashEntry.new(
            :key   => key.compile(context),
            :value => value.compile(context)
          )
        end
      end

      class ModuleBlock < Node
        def compile(context)
          if name !~ /^[A-Z][a-zA-Z0-9_]*$/
            raise NotImplementedError,
                  "Invalid module name: #{name.inspect}. Module names that are not Ruby class names are not supported."
          end

          class_statements = []

          context.inside self do |inner_context|
            class_statements += build_initialize_def(inner_context)
            class_statements += build_other_defs(inner_context)
            class_statements += build_publish_calls(inner_context)
          end

          Ruby::Program.new(
            :statements => Ruby::Statements.new(
              :statements => [
                Ruby::MethodCall.new(
                  :receiver => nil,
                  :name     => "require",
                  :args     => [Ruby::Literal.new(:value => "ycp")],
                  :block    => nil,
                  :parens   => false
                ),
                Ruby::Module.new(
                  :name       => "YCP",
                  :statements => Ruby::Statements.new(
                    :statements => [
                      Ruby::Class.new(
                        :name       => "#{name}Class",
                        :superclass => Ruby::Variable.new(:name => "Module"),
                        :statements => Ruby::Statements.new(
                          :statements => class_statements
                        )
                      ),
                      Ruby::Assignment.new(
                        :lhs => Ruby::Variable.new(:name => name),
                        :rhs => Ruby::MethodCall.new(
                          :receiver => Ruby::Variable.new(:name => "#{name}Class"),
                          :name     => "new",
                          :args     => [],
                          :block    => nil,
                          :parens   => true
                        )
                      )
                    ]
                  )
                )
              ]
            ),
            :comment    => comment
          )
        end

        private

        def fundef_statements
          statements.select { |s| s.is_a?(FunDef) }
        end

        def other_statements
          statements - fundef_statements
        end

        def constructor
          fundef_statements.find { |s| s.name == name }
        end

        def build_initialize_def(context)
          if !other_statements.empty? || constructor
            initialize_statements = other_statements.map { |s| s.compile(context) }

            if constructor
              initialize_statements << Ruby::MethodCall.new(
                :receiver => nil,
                :name     => name,
                :args     => [],
                :block    => nil,
                :parens   => true
              )
            end

            [
              Ruby::Def.new(
                :name       => "initialize",
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => initialize_statements
                )
              )
            ]
          else
            []
          end
        end

        def build_other_defs(context)
          fundef_statements.map { |t| t.compile(context) }
        end

        def build_publish_calls(context)
          exported_symbols = if context.export_private
            symbols
          else
            symbols.select(&:global)
          end

          exported_symbols.map { |s| s.compile_as_publish_call(context) }
        end
      end

      class Repeat < Node
        def symbols
          []
        end

        def compile(context)
          Ruby::Until.new(
            :condition => self.until.compile(context),
            :body      => Ruby::Begin.new(
              :statements => compile_statements_inside_block(self.do, context)
            )
          )
        end
      end

      class Return < Node
        def compile(context)
          case context.innermost(DefBlock, FileBlock, UnspecBlock)
            when DefBlock, FileBlock
              Ruby::Return.new(:value => child ? child.compile(context) : nil)
            when UnspecBlock
              Ruby::Next.new(:value => child ? child.compile(context) : nil)
            else
              raise "Misplaced \"return\" statement."
          end
        end
      end

      class StmtBlock < Node
        def compile(context)
          context.inside self do |inner_context|
            Ruby::Statements.new(
              :statements => statements.map { |s| s.compile(inner_context) }
            )
          end
        end
      end

      class Switch < Node
        def compile(context)
          Ruby::Case.new(
            :expression => cond.compile(context),
            :whens      => cases.map { |c| c.compile(context) },
            :else       => default ? default.compile(context) : nil
          )
        end
      end

      class Symbol < Node
        def needs_copy?
          immutable_types = [Type::BOOLEAN, Type::INTEGER, Type::SYMBOL]

          !immutable_types.include?(type.no_const) && !type.reference?
        end

        def compile(context)
          RubyVar.for(nil, name, context, :in_arg)
        end

        def compile_as_copy_arg_call(context)
          Ruby::Assignment.new(
            :lhs => RubyVar.for(nil, name, context, :in_code),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "deep_copy",
              :args     => [RubyVar.for(nil, name, context, :in_code)],
              :block    => nil,
              :parens   => true
            )
          )
        end

        def compile_as_publish_call(context)
          entries = [
            Ruby::HashEntry.new(
              :key   => Ruby::Literal.new(:value => category),
              :value => Ruby::Literal.new(:value => name.to_sym)
            ),
            Ruby::HashEntry.new(
              :key   => Ruby::Literal.new(:value => :type),
              :value => Ruby::Literal.new(:value => type.to_s)
            )
          ]

          unless global
            entries << Ruby::HashEntry.new(
              :key   => Ruby::Literal.new(:value => :private),
              :value => Ruby::Literal.new(:value => true)
            )
          end

          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "publish",
            :args     => [Ruby::Hash.new(:entries => entries)],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class Textdomain < Node
        def compile(context)
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "textdomain",
            :args     => [Ruby::Literal.new(:value => name)],
            :block    => nil,
            :parens   => false
          )
        end
      end

      class Typedef < Node
        def compile(context)
          # Ignored because ycpc expands defined types in the XML, so we never
          # actually encounter them.
        end
      end

      class UnspecBlock < Node
        def creates_local_scope?
          true
        end

        def compile(context)
          context.inside self do |inner_context|
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "lambda",
              :args     => [],
              :block    => Ruby::Block.new(
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => statements.map { |s| s.compile(inner_context) }
                )
              ),
              :parens   => true
            )
          end
        end

        def compile_as_block(context)
          context.inside self do |inner_context|
            Ruby::Block.new(
              :args       => args.map { |a| a.compile(inner_context) },
              :statements => Ruby::Statements.new(
                :statements => statements.map { |s| s.compile(inner_context) }
              )
            )
          end
        end
      end

      class Variable < Node
        def compile(context)
          case category
            when :variable, :reference
              RubyVar.for(ns, name, context, :in_code)
            when :function
              getter = if !ns && context.locals.include?(name)
                RubyVar.for(nil, name, context, :in_code)
              else
                # In the XML, all global module function references are
                # qualified (e.g. "M::i"). This includes references to functions
                # defined in this module. The problem is that in generated Ruby
                # code, the module namespace may not exist yet (e.g. when the
                # function is refrenced at module toplvel in YCP), so we have to
                # omit it (which is OK, because then the |method| call will be
                # invoked on |self|, whish is always our module).
                real_ns = ns == context.module_name ? nil : ns

                Ruby::MethodCall.new(
                  :receiver => real_ns ? Ruby::Variable.new(:name => real_ns) : nil,
                  :name     => "method",
                  :args     => [
                    Ruby::Literal.new(:value => name.to_sym)
                  ],
                  :block    => nil,
                  :parens   => true
                )
              end

              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "fun_ref",
                :args     => [getter, Ruby::Literal.new(:value => type.to_s)],
                :block    => nil,
                :parens   => true
              )
            else
              raise "Unknown variable category: #{category.inspect}."
          end
        end
      end

      class While < Node
        def symbols
          []
        end

        def compile(context)
          Ruby::While.new(
            :condition => cond.compile(context),
            :body      => compile_statements_inside_block(self.do, context)
          )
        end
      end

      class YCPCode < Node
        def creates_local_scope?
          true
        end

        def compile(context)
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "lambda",
            :args     => [],
            :block    => Ruby::Block.new(
              :args       => [],
              :statements => child.compile(context)
            ),
            :parens   => true
          )
        end

        def compile_as_block(context)
          context.inside self do |inner_context|
            Ruby::Block.new(
              :args       => args.map { |a| a.compile(inner_context) },
              :statements => child.compile(inner_context)
            )
          end
        end
      end

      class YEBinary < Node
        OPS_TO_OPS = {
          "&&" => "&&",
          "||" => "||"
        }

        OPS_TO_METHODS = {
          "+"  => "add",
          "-"  => "subtract",
          "*"  => "multiply",
          "/"  => "divide",
          "%"  => "modulo",
          "&"  => "bitwise_and",
          "|"  => "bitwise_or",
          "^"  => "bitwise_xor",
          "<<" => "shift_left",
          ">>" => "shift_right"
        }

        def compile(context)
          if OPS_TO_OPS[name]
            Ruby::BinaryOperator.new(
              :op  => OPS_TO_OPS[name],
              :lhs => lhs.compile(context),
              :rhs => rhs.compile(context)
            )
          elsif OPS_TO_METHODS[name]
            Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "Ops"),
              :name     => OPS_TO_METHODS[name],
              :args     => [lhs.compile(context), rhs.compile(context)],
              :block    => nil,
              :parens   => true
            )
          else
            raise "Unknown binary operator: #{name.inspect}."
          end
        end
      end

      class YEBracket < Node
        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "index",
            :args     => [
              value.compile(context),
              index.compile(context),
              default.compile(context),
            ],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class YEIs < Node
        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "is",
            :args     => [
              child.compile(context),
              Ruby::Literal.new(:value => type.to_s)
            ],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class YEPropagate < Node
        # Is identical to list of shortcuts in ruby-bindings ycp/convert.rb
        TYPES_WITH_SHORTCUT_CONVERSION = [
          "boolean",
          "float",
          "integer",
          "list",
          "locale",
          "map",
          "path",
          "string",
          "symbol",
          "term",
        ]
        def compile(context)
          if from.no_const != to.no_const
            if TYPES_WITH_SHORTCUT_CONVERSION.include?(to.to_s) && from.to_s == "any"
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "Convert"),
                :name     => "to_#{to}",
                :args     => [child.compile(context)],
                :block    => nil,
                :parens   => true
              )
            else
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "Convert"),
                :name     => "convert",
                :args     => [
                  child.compile(context),
                  Ruby::Hash.new(
                    :entries => [
                      Ruby::HashEntry.new(
                        :key   => Ruby::Literal.new(:value => :from),
                        :value => Ruby::Literal.new(:value => from.no_const.to_s)
                      ),
                      Ruby::HashEntry.new(
                        :key   => Ruby::Literal.new(:value => :to),
                        :value => Ruby::Literal.new(:value => to.no_const.to_s)
                      )
                    ]
                  )
                ],
                :block    => nil,
                :parens   => true
              )
            end
          else
            child.compile(context)
          end
        end
      end

      class YEReference < Node
        def compile(context)
          child.compile_as_ref(context)
        end

        def compile_as_setter(context)
          Ruby::Assignment.new(
            :lhs => compile(context),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "arg_ref",
              :args     => [child.compile(context)],
              :block    => nil,
              :parens   => true
            )
          )
        end

        def compile_as_getter(context)
          Ruby::Assignment.new(
            :lhs => child.compile(context),
            :rhs => Ruby::MethodCall.new(
              :receiver => compile(context),
              :name     => "value",
              :args     => [],
              :block    => nil,
              :parens   => true
            )
          )
        end
      end

      class YEReturn < Node
        def creates_local_scope?
          true
        end

        def compile(context)
          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "lambda",
            :args     => [],
            :block    => Ruby::Block.new(
              :args       => [],
              :statements => child.compile(context)
            ),
            :parens   => true
          )
        end

        def compile_as_block(context)
          context.inside self do |inner_context|
            Ruby::Block.new(
              :args       => args.map { |a| a.compile(inner_context) },
              :statements => child.compile(inner_context)
            )
          end
        end
      end

      class YETerm < Node
        UI_TERMS = [
          :BarGraph,
          :Bottom,
          :CheckBox,
          :ColoredLabel,
          :ComboBox,
          :Date,
          :DownloadProgress,
          :DumbTab,
          :DummySpecialWidget,
          :Empty,
          :Frame,
          :HBox,
          :HBoxvHCenter,
          :HMultiProgressMeter,
          :HSpacing,
          :HSquash,
          :HStretch,
          :HVCenter,
          :HVSquash,
          :HVStretch,
          :HWeight,
          :Heading,
          :IconButton,
          :Image,
          :IntField,
          :Label,
          :Left,
          :LogView,
          :MarginBox,
          :MenuButton,
          :MinHeight,
          :MinSize,
          :MinWidth,
          :MultiLineEdit,
          :MultiSelectionBox,
          :PackageSelector,
          :PatternSelector,
          :PartitionSplitter,
          :Password,
          :PkgSpecial,
          :ProgressBar,
          :PushButton,
          :RadioButton,
          :RadioButtonGroup,
          :ReplacePoint,
          :RichText,
          :Right,
          :SelectionBox,
          :Slider,
          :Table,
          :TextEntry,
          :Time,
          :Top,
          :Tree,
          :VBox,
          :VCenter,
          :VMultiProgressMeter,
          :VSpacing,
          :VSquash,
          :VStretch,
          :VWeight,
          :Wizard
        ]

        def compile(context)
          name_symbol = name.to_sym
          children_compiled = children.map { |ch| ch.compile(context) }
          if UI_TERMS.include?(name_symbol)
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => name,
              :args     => children_compiled,
              :block    => nil,
              :parens   => true
            )
          else
            name_compiled     = Ruby::Literal.new(:value => name_symbol)

            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "term",
              :args     => [name_compiled] + children_compiled,
              :block    => nil,
              :parens   => true
            )
          end
        end
      end

      class YETriple < Node
        def compile(context)
          Ruby::Ternary.new(
            :condition => cond.compile(context),
            :then      => self.true.compile(context),
            :else      => self.false.compile(context)
          )
        end
      end

      class YEUnary < Node
        OPS_TO_OPS = {
          "!"  => "!"
        }

        OPS_TO_METHODS = {
          "-"  => "unary_minus",
          "~"  => "bitwise_not",
        }

        def compile(context)
          if OPS_TO_OPS[name]
            Ruby::UnaryOperator.new(
              :op         => OPS_TO_OPS[name],
              :expression => child.compile(context)
            )
          elsif OPS_TO_METHODS[name]
            Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "Ops"),
              :name     => OPS_TO_METHODS[name],
              :args     => [child.compile(context)],
              :block    => nil,
              :parens   => true
            )
          else
            raise "Unknown unary operator: #{name.inspect}."
          end
        end
      end
    end
  end
end
