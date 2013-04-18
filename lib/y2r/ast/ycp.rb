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
          @blocks         = attrs[:blocks] || []
          @export_private = attrs[:export_private] || false
        end

        def in?(klass)
          @blocks.find { |b| b.is_a?(klass) } ? true : false
        end

        def innermost(*klasses)
          @blocks.reverse.find { |b| klasses.any? { |k| b.is_a?(k) } }
        end

        def module_name
          toplevel_block = @blocks.first
          toplevel_block.is_a?(ModuleBlock) ? toplevel_block.name : nil
        end

        def locals
          index = @blocks.index { |b| b.is_a?(DefBlock) || b.is_a?(UnspecBlock) || b.is_a?(YCPCode) || b.is_a?(YEReturn) } || @blocks.length
          @blocks[index..-1].map { |b| b.variables + b.functions }.flatten
        end

        def globals
          index = @blocks.index { |b| b.is_a?(DefBlock) || b.is_a?(UnspecBlock) || b.is_a?(YCPCode) || b.is_a?(YEReturn) } || @blocks.length
          @blocks[index..-1].map { |b| b.variables + b.functions }.flatten
        end
      end

      class Node < OpenStruct
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

        def inside_block(context)
          inner_context = context.dup
          inner_context.blocks = inner_context.blocks + [self]

          yield inner_context
        end

        def compile_statements(statements, context)
          if statements
            statements.compile(context)
          else
            Ruby::Statements.new(:statements => [])
          end
        end

        def compile_statements_inside_block(statements, context)
          inside_block context do |inner_context|
            compile_statements(statements, inner_context)
          end
        end

        def strip_const(type)
          type.sub(/^const /, "")
        end

        def qualified_name(ns, name)
          (ns ? "#{ns}::" : "") + name
        end

        # Escapes valid YCP variable names that are not valid Ruby local variable
        # names.
        def escape_ruby_local_var_name(name)
          name.sub(/^(#{RUBY_KEYWORDS.join("|")}|[A-Z_].*)$/) { |s| "_#{s}" }
        end

        # Builds a Ruby AST node for a variable with given name, doing all
        # necessary esaping, de-aliasing, etc.
        #
        # The biggest issue is that in the XML, all global module variable
        # references are qualified (e.g. "M::i"). This includes references to
        # variables defined in this module. All other variable references are
        # unqualified (e.g "i").
        #
        # Note that Y2R currently supports only local variables (translated as
        # Ruby local variables) and module-level variables (translated as Ruby
        # instance variables).
        def ruby_var(name, context)
          if name =~ /^([^:]+)::([^:]+)$/
            if $1 == context.module_name
              Ruby::Variable.new(:name => "@#$2")
            else
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => $1),
                :name     => $2,
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
              escape_ruby_local_var_name(suffixed_name)
            else
              "@#{suffixed_name}"
            end

            Ruby::Variable.new(:name => variable_name)
          end
        end
      end

      class Block < Node
        def variables
          symbols.select { |s| s.category == :variable }.map(&:name)
        end

        def functions
          symbols.select { |s| s.category == :function }.map(&:name)
        end
      end

      # Sorted alphabetically.

      class Assign < Node
        def compile(context)
          Ruby::Assignment.new(
            :lhs => ruby_var(name, context),
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
          module_name = case name
            when /^SCR::/
              "SCR"
            when /^WFM::/
              "WFM"
            when /^float::/
              "Builtins::Float"
            when /^list::/
              "Builtins::List"
            else
              "Builtins"
          end

          method_name = name.split("::").last

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => module_name),
            :name     => method_name,
            :args     => args.map { |a| a.compile(context) },
            :block    => block ? block.compile_as_block(context) : nil,
            :parens   => true
          )
        end
      end

      class Call < Node
        def compile(context)
          case category
            when "function"
              if context.locals.include?(name)
                Ruby::MethodCall.new(
                  :receiver => ruby_var(name, context),
                  :name     => "call",
                  :args     => args.map { |a| a.compile(context) },
                  :block    => nil,
                  :parens   => true
                )
              else
                Ruby::MethodCall.new(
                  :receiver => ns ? Ruby::Variable.new(:name => ns) : nil,
                  :name     => name,
                  :args     => args.map { |a| a.compile(context) },
                  :block    => nil,
                  :parens   => true
                )
              end
            when "variable" # function reference stored in variable
              Ruby::MethodCall.new(
                :receiver => ruby_var(qualified_name(ns, name), context),
                :name     => "call",
                :args     => args.map { |a| a.compile(context) },
                :block    => nil,
                :parens   => true
              )
            else
              raise "Unknown call category: #{category.inspect}."
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

      class DefBlock < Block
        def compile(context)
          inside_block context do |inner_context|
            Ruby::Statements.new(
              :statements => statements.map { |s| s.compile(inner_context) }
            )
          end
        end
      end

      class Do < Node
        def variables
          []
        end

        def functions
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
          ruby_var(qualified_name(ns, name), context)
        end
      end

      class FileBlock < Block
        def compile(context)
          client_name = File.basename(filename).sub(/\.[^.]*$/, "")
          class_name = client_name.
            gsub(/^./)     { |s| s.upcase    }.
            gsub(/[_.-]./) { |s| s[1].upcase } + "Client"

          textdomains = statements.select { |s| s.is_a?(Textdomain) }
          fundefs = statements.select { |s| s.is_a?(FunDef) }
          other_statements = statements - textdomains - fundefs

          class_statements = [
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "include",
              :args     => [Ruby::Variable.new(:name => "YCP")],
              :block    => nil,
              :parens   => false
            )
          ]

          inside_block context do |inner_context|
            class_statements += textdomains.map { |t| t.compile(inner_context) }

            unless other_statements.empty?
              class_statements << Ruby::Def.new(
                :name       => "main",
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => other_statements.map { |s| s.compile(inner_context) }
                )
              )
            end

            class_statements += fundefs.map { |f| f.compile(inner_context) }
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
            )
          )
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
          statements.statements = args.select(&:needs_copy?).map do |arg|
            arg.compile_as_copy_arg_call(context)
          end + statements.statements
          statements.statements << Ruby::Literal.new(:value => nil)

          if !context.in?(DefBlock)
            Ruby::Def.new(
              :name       => name,
              :args       => args.map { |a| a.compile(context) },
              :statements => statements
            )
          else
            Ruby::Assignment.new(
              :lhs => ruby_var(name, context),
              :rhs => Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "lambda",
                :args     => [],
                :block    => Ruby::Block.new(
                  :args       => args.map { |a| a.compile(context) },
                  :statements => statements
                ),
                :parens   => true
              )
            )
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

      class ModuleBlock < Block
        def compile(context)
          real_name = name.
            sub(/^./) { |s| s.upcase }.
            sub(/\.ycp$/, "")
          textdomains = statements.select { |s| s.is_a?(Textdomain) }
          fundefs = statements.select { |s| s.is_a?(FunDef) }
          other_statements = statements - textdomains - fundefs

          class_statements = [
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "include",
              :args     => [Ruby::Variable.new(:name => "YCP")],
              :block    => nil,
              :parens   => false
            ),
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "extend",
              :args     => [Ruby::Variable.new(:name => "Exportable")],
              :block    => nil,
              :parens   => false
            )
          ]

          inside_block context do |inner_context|
            class_statements += textdomains.map { |t| t.compile(inner_context) }

            unless other_statements.empty?
              class_statements << Ruby::Def.new(
                :name       => "initialize",
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => other_statements.map { |s| s.compile(inner_context) }
                )
              )
            end

            class_statements += fundefs.map { |f| f.compile(inner_context) }

            exported_symbols = if context.export_private
              symbols.select(&:exportable?)
            else
              symbols.select { |s| s.exportable? && s.global }
            end
            class_statements += exported_symbols.map do |symbol|
              symbol.compile_as_publish_call(inner_context)
            end
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
                        :name       => "#{real_name}Class",
                        :statements => Ruby::Statements.new(
                          :statements => class_statements
                        )
                      ),
                      Ruby::Assignment.new(
                        :lhs => Ruby::Variable.new(:name => real_name),
                        :rhs => Ruby::MethodCall.new(
                          :receiver => Ruby::Variable.new(:name => "#{real_name}Class"),
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
            )
          )
        end
      end

      class Repeat < Node
        def variables
          []
        end

        def functions
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

      class StmtBlock < Block
        def compile(context)
          inside_block context do |inner_context|
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
          strip_const(type) !~ /^(boolean|integer|symbol)$|&$/
        end

        def exportable?
          category == :variable || category == :function
        end

        def compile(context)
          Ruby::Arg.new(:name => ruby_name, :default => nil)
        end

        def compile_as_copy_arg_call(context)
          Ruby::Assignment.new(
            :lhs => Ruby::Variable.new(:name => ruby_name),
            :rhs => Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "copy_arg",
              :args     => [Ruby::Variable.new(:name => ruby_name)],
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
              :value => Ruby::Literal.new(:value => type)
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

        private

        def ruby_name
          escape_ruby_local_var_name(name)
        end
      end

      class Textdomain < Node
        def compile(context)
          Ruby::Statements.new(
            :statements => [
              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "include",
                :args     => [Ruby::Variable.new(:name => "I18n")],
                :block    => nil,
                :parens   => false
              ),
              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "textdomain",
                :args     => [Ruby::Literal.new(:value => name)],
                :block    => nil,
                :parens   => false
              )
            ]
          )
        end
      end

      class Typedef < Node
        def compile(context)
          # Ignored because ycpc expands defined types in the XML, so we never
          # actually encounter them.
        end
      end

      class UnspecBlock < Block
        def compile(context)
          inside_block context do |inner_context|
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
          inside_block context do |inner_context|
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
            when "variable", "reference"
              ruby_var(name, context)
            when "function"
              getter = if context.locals.include?(name)
                ruby_var(name, context)
              else
                parts = name.split("::")
                ns = parts.size > 1 ? parts.first : nil
                variable_name = parts.last

                Ruby::MethodCall.new(
                  :receiver => ns ? Ruby::Variable.new(:name => ns) : nil,
                  :name     => "method",
                  :args     => [
                    Ruby::Literal.new(:value => variable_name.to_sym)
                  ],
                  :block    => nil,
                  :parens   => true
                )
              end

              Ruby::MethodCall.new(
                :receiver => nil,
                :name     => "reference",
                :args     => [getter, Ruby::Literal.new(:value => type)],
                :block    => nil,
                :parens   => true
              )
            else
              raise "Unknown variable category: #{category.inspect}."
          end
        end
      end

      class While < Node
        def variables
          []
        end

        def functions
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
        def variables
          symbols.select { |s| s.category == :variable }.map(&:name)
        end

        def functions
          symbols.select { |s| s.category == :function }.map(&:name)
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
          inside_block context do |inner_context|
            Ruby::Block.new(
              :args       => args.map { |a| a.compile(inner_context) },
              :statements => child.compile(inner_context)
            )
          end
        end
      end

      class YEBinary < Node
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
          ">>" => "shift_right",
          "&&" => "logical_and",
          "||" => "logical_or"
        }

        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => OPS_TO_METHODS[name],
            :args     => [lhs.compile(context), rhs.compile(context)],
            :block    => nil,
            :parens   => true
          )
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
              Ruby::Literal.new(:value => type)
            ],
            :block    => nil,
            :parens   => true
          )
        end
      end

      class YEPropagate < Node
        def compile(context)
          from_no_const = strip_const(from)
          to_no_const   = strip_const(to)

          if from_no_const != to_no_const
            Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "Convert"),
              :name     => "convert",
              :args     => [
                child.compile(context),
                Ruby::Hash.new(
                  :entries => [
                    Ruby::HashEntry.new(
                      :key   => Ruby::Literal.new(:value => :from),
                      :value => Ruby::Literal.new(:value => from_no_const)
                    ),
                    Ruby::HashEntry.new(
                      :key   => Ruby::Literal.new(:value => :to),
                      :value => Ruby::Literal.new(:value => to_no_const)
                    )
                  ]
                )
              ],
              :block    => nil,
              :parens   => true
            )
          else
            child.compile(context)
          end
        end
      end

      class YEReference < Node
        def compile(context)
          child.compile(context)
        end
      end

      class YEReturn < Node
        def variables
          symbols.select { |s| s.category == :variable }.map(&:name)
        end

        def functions
          symbols.select { |s| s.category == :function }.map(&:name)
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
          inside_block context do |inner_context|
            Ruby::Block.new(
              :args       => args.map { |a| a.compile(inner_context) },
              :statements => child.compile(inner_context)
            )
          end
        end
      end

      class YETerm < Node
        def compile(context)
          name_compiled     = Ruby::Literal.new(:value => name.to_sym)
          children_compiled = children.map { |ch| ch.compile(context) }

          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "term",
            :args     => [name_compiled] + children_compiled,
            :block    => nil,
            :parens   => true
          )
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
        OPS_TO_METHODS = {
          "-"  => "unary_minus",
          "~"  => "bitwise_not",
          "!"  => "logical_not"
        }

        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => OPS_TO_METHODS[name],
            :args     => [child.compile(context)],
            :block    => nil,
            :parens   => true
          )
        end
      end
    end
  end
end
