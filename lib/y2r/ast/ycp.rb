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
      class CompilerContext < OpenStruct
        def in?(klass)
          blocks.find { |b| b.is_a?(klass) } ? true : false
        end

        def innermost(*klasses)
          blocks.reverse.find { |b| klasses.any? { |k| b.is_a?(k) } }
        end

        def inside(block)
          context = dup
          context.blocks = blocks + [block]

          yield context
        end

        def drop_whitespace
          context = dup
          context.whitespace = :drop
          context
        end

        def keep_whitespace
          context = dup
          context.whitespace = :keep
          context
        end

        def module_name
          blocks.first.name
        end

        def symbols
          blocks.map { |b| b.symbols.map(&:name) }.flatten
        end

        def locals
          index = blocks.index(&:creates_local_scope?) || blocks.length
          blocks[index..-1].map { |b| b.symbols.map(&:name) }.flatten
        end

        def globals
          index = blocks.index(&:creates_local_scope?) || blocks.length
          blocks[0..index].map { |b| b.symbols.map(&:name) }.flatten
        end

        def symbol_for(name)
          symbols = blocks.map { |b| b.symbols }.flatten
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

        def needs_copy?
          !IMMUTABLE_TYPES.include?(no_const) && !reference?
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
        STRING  = Type.new("string")
        PATH    = Type.new("path")

        IMMUTABLE_TYPES = [BOOLEAN, INTEGER, SYMBOL, STRING, PATH]
      end

      # Contains utility functions related to comment processing.
      module Comments
        COMMENT_SPLITTING_REGEXP = /
          \#[^\n]*(\n|$)         # one-line hash comment
          |
          \/\/[^\n]*(\n|$)       # one-line slash comment
          |
          \/\*                   # multi-line comment
          (
            [^*]|\*(?!\/)
          )*
          \*\/
          |
          ((?!\#|\/\/|\/\*).)+   # non-comment
        /xm

        class << self
          def process_comment_before(comment, options)
            comment = fix_delimiters(comment)
            comment = strip_leading_whitespace(comment)
            comment = strip_trailing_whitespace(comment)

            if options[:whitespace] == :drop
              comment = drop_leading_empty_lines(comment)
              comment = drop_trailing_empty_lines(comment)

              # In whitespace-dropping mode we want to remove empty comments
              # completely. Note that returning "" instead of nil would not be
              # enough, at that would cause adding a newline into the generated
              # code at some places.
              comment = nil if comment.empty?
            else
              # In many before comments, there is a line of whitespace caused by
              # separation of the comment from the node it belongs to. For
              # example, in this case, the comment and the node are separated by
              # "\n  ":
              #
              #   {
              #     /* Comment */
              #     y2milestone("M1");
              #   }
              #
              # We need to remove such lines of whitespace (which are now empty
              # because of whitespace stripping above), but not touch any
              # additional ones).
              comment = drop_trailing_empty_line(comment)
            end

            comment
          end

          def process_comment_after(comment, options)
            comment = fix_delimiters(comment)
            comment = strip_leading_whitespace(comment)
            comment = strip_trailing_whitespace(comment)

            if options[:whitespace] == :drop
              comment = drop_leading_empty_lines(comment)
              comment = drop_trailing_empty_lines(comment)

              # In whitespace-dropping mode we want to remove empty comments
              # completely. Note that returning "" instead of nil would not be
              # enough, at that would cause adding a newline into the generated
              # code at some places.
              comment = nil if comment.empty?
            end

            comment
          end

          private

          def fix_delimiters(comment)
            fixed_comment = ""

            comment.scan(COMMENT_SPLITTING_REGEXP) do
              segment = $&

              case segment
                when /\A\/\//   # one-line slash comment
                  segment.sub!(/^\/\//, "#")

                when /\A\/\*/    # multi-line comment
                  is_doc_comment = segment =~ /\/\*\*\n/

                  if is_doc_comment
                    segment.sub!(/^\/\*\*\n/, "")   # leading "/**\n"
                  else
                    segment.sub!(/^\/\*/, "")       # leading "/*"
                  end

                  segment.sub!(/\*\/$/, "")         # trailing "*/"
                  segment.sub!(/^[ \t]*\n/, "")     # leading empty lines
                  segment.sub!(/(\n[ \t]*)$/, "")   # trailing empty lines

                  if segment.split("\n").all? { |l| l =~ /^[ \t]*\*/ }
                    segment.gsub!(/^[ \t]*\*/, "")
                  end

                  segment.gsub!(/^/, "#")
              end

              fixed_comment << segment
            end

            fixed_comment
          end

          def strip_leading_whitespace(comment)
            comment.gsub(/^[ \t]+/, "")
          end

          def strip_trailing_whitespace(comment)
            comment.gsub(/[ \t]+$/, "")
          end

          def drop_leading_empty_lines(comment)
            comment.gsub(/\A\n*/, "")
          end

          def drop_trailing_empty_lines(comment)
            comment.gsub(/\n*\z/, "")
          end

          def drop_trailing_empty_line(comment)
            comment.sub(/\n\z/, "")
          end
        end
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
        class << self
          def transfers_comments(*names)
            names.each do |name|
              name_without_comments = :"#{name}_without_comments"
              name_with_comments    = :"#{name}_with_comments"

              define_method name_with_comments do |context|
                whitespace = context.whitespace
                context = context.drop_whitespace if context.whitespace == :keep

                node = send(name_without_comments, context)
                if node
                  if comment_before
                    processed_comment_before = Comments.process_comment_before(
                      comment_before,
                      :whitespace => whitespace
                    )
                    if processed_comment_before
                      node.comment_before = processed_comment_before
                    end
                  end

                  if comment_after
                    processed_comment_after = Comments.process_comment_after(
                      comment_after,
                      :whitespace => whitespace
                    )
                    if processed_comment_after
                      node.comment_after = processed_comment_after
                    end
                  end
                end
                node
              end

              alias_method name_without_comments, name
              alias_method name, name_with_comments
            end
          end
        end

        def creates_local_scope?
          false
        end

        # `Ops` exists because YCP does not have exceptions and nil propagates
        # to operation results. If we use a Ruby operator where the YaST program
        # can produce `nil`, we would crash with an exception. If we know that 
        # `nil` cannot be there, we ca use a plain ruby operator.
        def never_nil?
          false
        end

        def needs_copy?
          false
        end

        # In Ruby, methods return value of last expresion if no return statement
        # is encountered. To match YaST's behavior in this case (returning nil),
        # we need to append nil at the end, unless we are sure some statement in
        # the method always causes early return. These early returns are detected
        # using this method.
        def always_returns?
          false
        end

        def compile_as_copy_if_needed(context)
          compile(context)
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
            :rhs => child.compile_as_copy_if_needed(context)
          )
        end

        transfers_comments :compile
      end

      class Bracket < Node
        def compile(context)
          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "assign",
            :args     => [
              entry.compile(context),
              build_index(context),
              rhs.compile(context),
            ],
            :block    => nil,
            :parens   => true
          )
        end

        transfers_comments :compile

        private

        def build_index(context)
          if arg.children.size == 1
            arg.children.first.compile(context)
          else
            arg.compile(context)
          end
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

        transfers_comments :compile
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

        transfers_comments :compile
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

        transfers_comments :compile
      end

      class Case < Node
        def compile(context)
          if body.statements.last.is_a?(Break)
            # The following dance is here because we want ot keep the AST nodes
            # immutable and thus avoid modifying their data.

            body_without_break = body.dup
            body_without_break.statements = body.statements[0..-2]
          elsif body.always_returns?
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

        def always_returns?
          body.always_returns?
        end

        transfers_comments :compile
      end

      class Compare < Node
        OPS_TO_OPS = {
          "==" => "==",
          "!=" => "!="
        }

        OPS_TO_METHODS = {
          "<"  => "less_than",
          ">"  => "greater_than",
          "<=" => "less_or_equal",
          ">=" => "greater_or_equal"
        }

        def compile(context)
          if OPS_TO_OPS[op]
            Ruby::BinaryOperator.new(
              :op       => OPS_TO_OPS[op],
              :lhs      => lhs.compile(context),
              :rhs      => rhs.compile(context)
            )
          elsif OPS_TO_METHODS[op]
            Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "Ops"),
              :name     => OPS_TO_METHODS[op],
              :args     => [lhs.compile(context), rhs.compile(context)],
              :block    => nil,
              :parens   => true
            )
          else
            raise "Unknown compare operator #{op}."
          end
        end

        transfers_comments :compile
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

        transfers_comments :compile

        def never_nil?
          return type != :void
        end
      end

      class Continue < Node
        def compile(context)
          Ruby::Next.new
        end

        transfers_comments :compile
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

        def always_returns?
          body.always_returns?
        end

        transfers_comments :compile
      end

      class DefBlock < Node
        def creates_local_scope?
          true
        end

        def compile(context)
          context.inside self do |inner_context|
            inner_context = inner_context.keep_whitespace

            Ruby::Statements.new(
              :statements => statements.map { |s| s.compile(inner_context) }
            )
          end
        end

        def always_returns?
          statements.any? {|s| s.always_returns? }
        end

        transfers_comments :compile
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

        transfers_comments :compile
      end

      class Entry < Node
        def compile(context)
          RubyVar.for(ns, name, context, :in_code)
        end

        def compile_as_ref(context)
          Ruby::Variable.new(:name => "#{name}_ref")
        end

        transfers_comments :compile, :compile_as_ref
      end

      class FileBlock < Node
        def name
          nil
        end

        def compile(context)
          class_statements = []

          context.inside self do |inner_context|
            inner_context = inner_context.keep_whitespace

            class_statements += build_main_def(inner_context)
            class_statements += build_other_defs(inner_context)
          end

          Ruby::Program.new(
            :filename   => filename,
            :statements => Ruby::Statements.new(
              :statements => [
                Ruby::Module.new(
                  :name       => "Yast",
                  :statements => Ruby::Class.new(
                    :name       => class_name,
                    :superclass => Ruby::Variable.new(:name => "Client"),
                    :statements => Ruby::Statements.new(
                      :statements => class_statements
                    )
                  )
                ),
                Ruby::MethodCall.new(
                  :receiver       => Ruby::MethodCall.new(
                    :receiver => Ruby::ConstAccess.new(
                      :receiver => Ruby::Variable.new(:name => "Yast"),
                      :name     => class_name
                    ),
                    :name     => "new",
                    :args     => [],
                    :block    => nil,
                    :parens   => true
                  ),
                  :name           => "main",
                  :args           => [],
                  :block          => nil,
                  :parens         => true,
                  :comment_before => ""
                )
              ]
            )
          )
        end

        transfers_comments :compile

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

            unless other_statements.any? {|s| s.always_returns? }
              main_statements << Ruby::Literal.new(:value => nil)
            end

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

            unless block.always_returns?
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

        transfers_comments :compile
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

        def always_returns?
          if self.then && self.else
            self.then.always_returns? && self.else.always_returns?
          else
            # If there is just one branch present, execution can always
            # continue because the branch may not be taken.
            false
          end
        end

        transfers_comments :compile
      end

      class Import < Node
        def compile(context)
          # Using any SCR or WFM function results in an auto-import. We ignore
          # these auto-imports becasue neither SCR nor WFM are real modules.
          return nil if name == "SCR" || name == "WFM"

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Yast"),
            :name     => "import",
            :args     => [Ruby::Literal.new(:value => name)],
            :block    => nil,
            :parens   => true
          )
        end

        transfers_comments :compile
      end

      class Include < Node
        def compile(context)
          args = [
            if context.options[:as_include_file]
              Ruby::Variable.new(:name => "include_target")
            else
              Ruby::Self.new
            end,
            Ruby::Literal.new(:value => name.sub(/\.y(cp|h)$/, ".rb"))
          ]

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Yast"),
            :name     => "include",
            :args     => args,
            :block    => nil,
            :parens   => true
          )
        end

        transfers_comments :compile
      end

      class IncludeBlock < Node
        def compile(context)
          class_statements = []

          context.inside self do |inner_context|
            inner_context = inner_context.keep_whitespace

            class_statements += build_initialize_method_def(inner_context)
            class_statements += build_other_defs(inner_context)
          end

          Ruby::Program.new(
            :filename   => filename,
            :statements => Ruby::Statements.new(
              :statements => [
                Ruby::Module.new(
                  :name       => "Yast",
                  :statements => Ruby::Module.new(
                    :name       => module_name,
                    :statements => Ruby::Statements.new(
                      :statements => class_statements
                    )
                  )
                )
              ]
            )
          )
        end

        transfers_comments :compile

        private

        def module_name
          parts = path_parts.map do |part|
            part.
              gsub(/^./)     { |s| s.upcase    }.
              gsub(/[_.-]./) { |s| s[1].upcase }
          end

          "#{parts.join("")}Include"
        end

        def initialize_method_name
          parts = path_parts.map { |p| p.gsub(/[_.-]/, "_") }

          "initialize_#{parts.join("_")}"
        end

        def path_parts
          path = if filename =~ /src\/include\//
            filename.sub(/^.*src\/include\//, "")
          else
            File.basename(filename)
          end

          path.sub(/\.y(cp|h)$/, "").split("/")
        end

        def fundef_statements
          statements.select { |s| s.is_a?(FunDef) }
        end

        def other_statements
          statements - fundef_statements
        end

        def build_initialize_method_def(context)
          if !other_statements.empty?
            initialize_method_statements = other_statements.map { |s| s.compile(context) }

            [
              Ruby::Def.new(
                :name       => initialize_method_name,
                :args       => [Ruby::Variable.new(:name => "include_target")],
                :statements => Ruby::Statements.new(
                  :statements => initialize_method_statements
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

      class List < Node
        def compile(context)
          Ruby::Array.new(
            :elements => children.map { |ch| ch.compile(context) }
          )
        end

        transfers_comments :compile
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

        transfers_comments :compile

        def never_nil?
          #locale can be only with constant strings
          return true
        end
      end

      class Map < Node
        def compile(context)
          Ruby::Hash.new(:entries => children.map { |ch| ch.compile(context) })
        end

        transfers_comments :compile
      end

      class MapElement < Node
        def compile(context)
          Ruby::HashEntry.new(
            :key   => key.compile(context),
            :value => value.compile(context)
          )
        end

        transfers_comments :compile
      end

      class ModuleBlock < Node
        def compile(context)
          if name !~ /^[A-Z][a-zA-Z0-9_]*$/
            raise NotImplementedError,
                  "Invalid module name: #{name.inspect}. Module names that are not Ruby class names are not supported."
          end

          class_statements = []

          context.inside self do |inner_context|
            inner_context = inner_context.keep_whitespace

            class_statements += build_main_def(inner_context)
            class_statements += build_other_defs(inner_context)
            class_statements += build_publish_calls(inner_context)
          end

          module_statements = [
            Ruby::Class.new(
              :name       => "#{name}Class",
              :superclass => Ruby::Variable.new(:name => "Module"),
              :statements => Ruby::Statements.new(
                :statements => class_statements
              )
            ),
            Ruby::Assignment.new(
              :lhs            => Ruby::Variable.new(:name => name),
              :rhs            => Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "#{name}Class"),
                :name     => "new",
                :args     => [],
                :block    => nil,
                :parens   => true
              ),
              :comment_before => ""
            )
          ]

          if has_main_def?
            module_statements << Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => name),
              :name     => "main",
              :args     => [],
              :block    => nil,
              :parens   => true
            )
          end

          Ruby::Program.new(
            :filename   => filename,
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
                  :name           => "Yast",
                  :statements     => Ruby::Statements.new(
                    :statements => module_statements
                  ),
                  :comment_before => ""
                )
              ]
            )
          )
        end

        transfers_comments :compile

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

        def has_main_def?
          !other_statements.empty? || constructor
        end

        def build_main_def(context)
          if has_main_def?
            main_statements = other_statements.map { |s| s.compile(context) }

            if constructor
              main_statements << Ruby::MethodCall.new(
                :receiver => nil,
                :name     => name,
                :args     => [],
                :block    => nil,
                :parens   => true
              )
            end

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

        def build_publish_calls(context)
          exported_symbols = if context.options[:export_private]
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

        transfers_comments :compile
      end

      class Return < Node
        def compile(context)
          case context.innermost(DefBlock, FileBlock, UnspecBlock)
            when DefBlock, FileBlock
              Ruby::Return.new(
                :value => child ? child.compile_as_copy_if_needed(context) : nil
              )
            when UnspecBlock
              Ruby::Next.new(
                :value => child ? child.compile_as_copy_if_needed(context) : nil
              )
            else
              raise "Misplaced \"return\" statement."
          end
        end

        def always_returns?
          true
        end

        transfers_comments :compile
      end

      class StmtBlock < Node
        def compile(context)
          context.inside self do |inner_context|
            inner_context = inner_context.keep_whitespace

            Ruby::Statements.new(
              :statements => statements.map { |s| s.compile(inner_context) }
            )
          end
        end

        def always_returns?
          statements.any? { |s| s.always_returns? }
        end

        transfers_comments :compile
      end

      class Switch < Node
        def compile(context)
          Ruby::Case.new(
            :expression => cond.compile(context),
            :whens      => cases.map { |c| c.compile(context) },
            :else       => default ? default.compile(context) : nil
          )
        end

        def always_returns?
          if self.default
            cases.all? { |c| c.always_returns? } && default.always_returns?
          else
            # If there is no default clause present, execution can always
            # continue because the tested expression may not fit any of the
            # cases.
            false
          end
        end

        transfers_comments :compile
      end

      class Symbol < Node
        def needs_copy?
          type.needs_copy?
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

        transfers_comments :compile
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

        transfers_comments :compile
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

        transfers_comments :compile, :compile_as_block
      end

      class Variable < Node
        def needs_copy?
          case category
            when :variable, :reference
              type.needs_copy?
            when :function
              false
            else
              raise "Unknown variable category: #{category.inspect}."
          end
        end

        def compile_as_copy_if_needed(context)
          node = compile(context)

          if needs_copy?
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "deep_copy",
              :args     => [node],
              :block    => nil,
              :parens   => true
            )
          else
            node
          end
        end

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

        transfers_comments :compile
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

        transfers_comments :compile
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

        transfers_comments :compile, :compile_as_block
      end

      class YEBinary < Node
        OPS_TO_OPS = {
          "&&" => "&&",
          "||" => "||"
        }

        OPS_TO_OPS_OPTIONAL = {
          "+"  => "+",
          "-"  => "-",
          "*"  => "*",
          "/"  => "/",
          "%"  => "%",
          "&"  => "&",
          "|"  => "|",
          "^"  => "^",
          "<<" => "<<",
          ">>" => ">>",
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
            if never_nil?
              Ruby::BinaryOperator.new(
                :op  => OPS_TO_OPS_OPTIONAL[name],
                :lhs => lhs.compile(context),
                :rhs => rhs.compile(context)
              )
            else
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "Ops"),
                :name     => OPS_TO_METHODS[name],
                :args     => [lhs.compile(context), rhs.compile(context)],
                :block    => nil,
                :parens   => true
              )
            end
          else
            raise "Unknown binary operator: #{name.inspect}."
          end
        end

        transfers_comments :compile

        def never_nil?
          return lhs.never_nil? && rhs.never_nil?
        end
      end

      class YEBracket < Node
        def compile(context)
          # In expressions like |m["foo"]:f()|, the |f| function is called only
          # when the value is missing. In other words, the default is evaluated
          # lazily. We need to emulate this laziness at least for the calls.
          if default.is_a?(Call)
            args  = [value.compile(context), build_index(context)]
            block = Ruby::Block.new(
              :args       => [],
              :statements => default.compile(context)
            )
          else
            args  = [
              value.compile(context),
              build_index(context),
            ]

            if !(default.is_a?(Const) && default.type == :void)
              args << default.compile(context)
            end

            block = nil
          end

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "index",
            :args     => args,
            :block    => block,
            :parens   => true
          )
        end

        transfers_comments :compile

        private

        def build_index(context)
          if index.children.size == 1
            index.children.first.compile(context)
          else
            index.compile(context)
          end
        end
      end

      class YEIs < Node
        KNOWN_SHORTCUTS = [
          'any',
          'boolean',
          'byteblock',
          'float',
          'integer',
          'list',
          'locale',
          'map',
          'path',
          'string',
          'symbol',
          'term',
          'void',
        ]

        def compile(context)
          if KNOWN_SHORTCUTS.include?(type.to_s)
            Ruby::MethodCall.new(
              :receiver => Ruby::Variable.new(:name => "Ops"),
              :name     => "is_#{type}?",
              :args     => [
                child.compile(context)
              ],
              :block    => nil,
              :parens   => true
            )
          else
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

        transfers_comments :compile
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
            if compile_as_shortcut?
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "Convert"),
                :name     => "to_#{to.no_const}",
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

        transfers_comments :compile

        private

        def compile_as_shortcut?
          shortcut_exists = TYPES_WITH_SHORTCUT_CONVERSION.include?(to.no_const.to_s)
          from_any        = from.no_const.to_s == "any"

          from_any && shortcut_exists
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

        transfers_comments :compile, :compile_as_setter, :compile_as_getter
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

        transfers_comments :compile, :compile_as_block
      end

      class YETerm < Node
        UI_TERMS = [
          :BarGraph,
          :BusyIndicator,
          :Bottom,
          :ButtonBox,
          :Cell,
          :Center,
          :CheckBox,
          :CheckBoxFrame,
          :ColoredLabel, 
          :ComboBox,
          :DateField,
          :DownloadProgress,
          :DumbTab,
          :Dummy,
          :DummySpecialWidget,
          :Empty,
          :Frame,
          :HBox,
          :HCenter,
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
          :InputField,
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
          :TimeField,
          :TimezoneSelector,
          :Top,
          :Tree,
          :VBox,
          :VCenter,
          :VMultiProgressMeter,
          :VSpacing,
          :VSquash,
          :VStretch,
          :VWeight,
          :Wizard,
          # special ones that will have upper case shortcut, but in term is lowercase
          :id,
          :item,
          :header,
          :opt,
        ]

        def compile(context)
          children_compiled = children.map { |ch| ch.compile(context) }

          method_name = name.dup
          method_name[0] = method_name[0].upcase
          if UI_TERMS.include?(name.to_sym) && !context.symbols.include?(method_name)
            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => method_name,
              :args     => children_compiled,
              :block    => nil,
              :parens   => true
            )
          else
            name_compiled = Ruby::Literal.new(:value => name.to_sym)

            Ruby::MethodCall.new(
              :receiver => nil,
              :name     => "term",
              :args     => [name_compiled] + children_compiled,
              :block    => nil,
              :parens   => true
            )
          end
        end

        transfers_comments :compile
      end

      class YETriple < Node
        def compile(context)
          Ruby::TernaryOperator.new(
            :condition => cond.compile(context),
            :then      => self.true.compile(context),
            :else      => self.false.compile(context)
          )
        end

        transfers_comments :compile

        def never_nil?
          return self.true.never_nil? && self.false.never_nil?
        end
      end

      class YEUnary < Node
        OPS_TO_OPS = {
          "!"  => "!"
        }

        OPS_TO_OPS_OPTIONAL = {
          "-"  => "-",
          "~"  => "~",
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
            if never_nil?
              Ruby::UnaryOperator.new(
                :op         => OPS_TO_OPS_OPTIONAL[name],
                :expression => child.compile(context)
              )
            else
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "Ops"),
                :name     => OPS_TO_METHODS[name],
                :args     => [child.compile(context)],
                :block    => nil,
                :parens   => true
              )
            end
          else
            raise "Unknown unary operator: #{name.inspect}."
          end
        end

        transfers_comments :compile

        def never_nil?
          return child.never_nil?
        end
      end
    end
  end
end
