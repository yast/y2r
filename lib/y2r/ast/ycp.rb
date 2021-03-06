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
        def at_toplevel?
          !blocks.any?(&:creates_local_scope?)
        end

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

        def with_whitespace(whitespace)
          context = dup
          context.whitespace = whitespace
          context
        end

        # elsif_mode is enabled iff the `If` node contain `If` node in its
        # else branch. In this mode ifs are translated as `elsif`.
        def enable_elsif
          context = dup
          context.elsif_mode = true
          context
        end

        def disable_elsif
          context = dup
          context.elsif_mode = false
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
          nesting_level = 0

          # First, extract content of the parens with arguments. This is a bit
          # tricky, as they don't have to be the first parens in the type
          # specification. For example, a type of function returning a reference
          # to a function returning integer looks like this:
          #
          #   integer()()
          #
          in_parens = ""
          @type.each_char do |ch|
            case ch
              when '('
                in_parens = "" if nesting_level == 0
                nesting_level += 1
              when ')'
                nesting_level -= 1
              else
                in_parens += ch
            end
          end

          types = []
          type = ""
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

        YAST_TYPES_REGEXP = /(void|any|boolean|string|symbol|integer|float|term|path|byteblock|block\s*<.*>|list(\s*<.*>|)|map(\s*<.*>|))/

        # Value of CompilerContext#whitespace.
        class Whitespace < OpenStruct
          def drop_before_above?
            drop_before_above
          end

          def drop_before_below?
            drop_before_below
          end

          def drop_after_above?
            drop_after_above
          end

          def drop_after_below?
            drop_after_below
          end

          KEEP_ALL = Whitespace.new
          DROP_ALL = Whitespace.new(
            :drop_before_above => true,
            :drop_before_below => true,
            :drop_after_above  => true,
            :drop_after_below  => true
          )
        end

        class << self
          def process_comment_before(node, comment, options)
            whitespace = options[:whitespace]

            comment = fix_delimiters(node, comment)
            comment = strip_leading_whitespace(comment)
            comment = strip_trailing_whitespace(comment)

            if whitespace.drop_before_above?
              comment = drop_leading_empty_lines(comment)
            end

            if whitespace.drop_before_below?
              comment = drop_trailing_empty_lines(comment)
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

            # In whitespace-dropping mode we want to remove empty comments
            # completely. Note that returning "" instead of nil would not be
            # enough, at that would cause adding a newline into the generated
            # code at some places.
            if whitespace.drop_before_above? || whitespace.drop_before_below?
              comment = nil if comment.empty?
            end

            comment
          end

          def process_comment_after(node, comment, options)
            whitespace = options[:whitespace]

            comment = fix_delimiters(node, comment)
            comment = strip_leading_whitespace(comment)
            comment = strip_trailing_whitespace(comment)

            if whitespace.drop_after_above?
              comment = drop_leading_empty_lines(comment)
            end

            if whitespace.drop_after_below?
              comment = drop_trailing_empty_lines(comment)
            end

            # In whitespace-dropping mode we want to remove empty comments
            # completely. Note that returning "" instead of nil would not be
            # enough, at that would cause adding a newline into the generated
            # code at some places.
            if whitespace.drop_after_above? || whitespace.drop_after_below?
              comment = nil if comment.empty?
            end

            comment
          end

          private

          def fix_delimiters(node, comment)
            fixed_comment = ""

            comment.scan(COMMENT_SPLITTING_REGEXP) do
              segment = $&
              prefix  = $`.split("\n").last || ""

              if segment =~ /\A\/\//
                segment = fix_single_line_segment(node, segment)
              elsif segment =~ /\A\/\*/
                segment = fix_multi_line_segment(node, segment, prefix)
              end

              fixed_comment << segment
            end

            fixed_comment
          end

          def strip_leading_whitespace(s)
            s.gsub(/^[ \t]+/, "")
          end

          def strip_trailing_whitespace(s)
            s.gsub(/[ \t]+$/, "")
          end

          def drop_leading_empty_lines(s)
            s.gsub(/\A\n*/, "")
          end

          def drop_trailing_empty_lines(s)
            s.gsub(/\n*\z/, "")
          end

          def drop_trailing_empty_line(s)
            s.sub(/\n\z/, "")
          end

          def fix_single_line_segment(node, segment)
            segment.sub(/\A\/\//, "#")
          end

          # Converts YCP type name to Ruby type name.
          def ycp_to_ruby_type(type)
            # unknown type, no change
            return type unless type.match "^#{YAST_TYPES_REGEXP}$"

            # ruby class names start with upcase letter
            upper_case_names = ["boolean", "string", "symbol", "float"]
            upper_case_names.each do |upper_case_name|
              type.gsub!(upper_case_name) { |s| s.capitalize }
            end

            # integer -> Fixnum
            type.gsub! "integer", "Fixnum"

            # any -> Object
            # "Object" is actually not 100% correct as only some types make
            # sense, but "any" would be even worse (does not exist in Ruby)
            type.gsub! "any", "Object"

            # list -> Array
            type.gsub! /list\s*/, "Array"

            # map -> Hash
            # yard uses '=>' delimiter
            type.gsub! /map(\s*<\s*(\S+)\s*,\s*(\S+)\s*>|)/ do
              if $2 && $3
                "Hash{#{$2} => #{$3}}"
              else
                "Hash"
              end
            end

            # path -> Yast::Path
            type.gsub! "path", "Yast::Path"

            # term -> Yast::Term
            type.gsub! "term", "Yast::Term"

            # byteblock -> Yast::Byteblock
            type.gsub! "byteblock", "Yast::Byteblock"

            # block<type> -> Proc
            type.gsub! /block\s*<.*>/, "Proc"

            type
          end

          # Process the original doc comment so that it works with YARD.
          def process_doc_comment(node, segment)

            # remove colon after a tag (it is ignored by ycpdoc)
            segment.gsub! /^(#\s+@\S+):/, "\\1"

            # remove @short tags, just add an empty line to use it
            # as the short description
            segment.gsub! /^(#\s+)@short\s+(.*)$/, "\\1\\2\n#"

            # remove @descr tags, not needed
            segment.gsub! /^(#\s+)@descr\s+/, "\\1"

            # add parameter type info
            if node.args
              node.args.each do |arg|
                segment.gsub! /^(#\s+@param)(s|)\s+(#{YAST_TYPES_REGEXP}\s+|)#{arg.name}\b/,
                  "\\1 [#{ycp_to_ruby_type(arg.type.to_s)}] #{arg.name}"
              end
            end

            # @return(s) type -> @return [type], the type is optional
            segment.gsub!(/^(#\s+@return)(s|)(\s+)(#{YAST_TYPES_REGEXP}|)/) do
              if $4.empty?
                "#{$1}#{$3}"
              else
                "#{$1}#{$3}[#{ycp_to_ruby_type($4)}]"
              end
            end

            # @internal -> @api private
            segment.gsub! /^(#\s+)@internal\b/, "\\1@api private"

            # @stable -> @note stable
            segment.gsub! /^(#\s+)@stable\b/,
              "\\1@note This is a stable API function"

            # @unstable -> @note unstable
            segment.gsub! /^(#\s+)@unstable\b/,
              "\\1@note This is an unstable API function and may change in the future"

            # @screenshot -> ![ALT text](path)
            # uses markdown syntax
            segment.gsub! /^(#\s+)@screenshot\s+(\S+)/,
              "\\1![\\2](../../\\2)"

            # @example_file -> {include:file:<file>}
            segment.gsub!(/^(#\s+)@example_file\s+(\S+)/) do
              "#{$1}Example file (#{$2}): {include:file:#{$2.gsub /\.ycp$/, '.rb'}}"
            end

            # @see Foo -> @see #Foo
            # @see Foo() -> @see #Foo
            # do not change if there are multiple words
            # (likely it refers to something else than a function name)
            segment.gsub! /^(#\s+)@see\s+(\S+)(\(\)|)\s*$/, "\\1@see #\\2"

            # @ref function -> {#function}, can be present anywhere in the text
            segment.gsub! /@ref\s+(#|)(\S+)/, "{#\\2}"

            # @struct and @tuple -> "  " (Extra indent to start a block)
            # multiline tag, needs line processing
            in_struct = false
            ret = ""
            segment.each_line do |line|
              if line.match /^#\s+@(struct|tuple)/
                in_struct = true

                # add header
                line.gsub! /^#\s+@struct(.*)$/, "#\n# **Structure:**\n#\n#    \\1"
                line.gsub! /^#\s+@tuple(.*)$/, "#\n# **Tuple:**\n#\n#    \\1"
                ret << line
              else
                if in_struct
                  # empty line or a new tag closes the tag
                  if line.match(/^#\s*$/) || line.match(/^#\s*@/)
                    in_struct = false
                  else
                    # indent the struct/tuple block
                    line.gsub! /^#(\s+.*)$/, "#     \\1"
                  end
                end

                ret << line
              end
            end

            ret
          end

          def fix_multi_line_segment(node, segment, prefix)
            # The [^*] part is needed to exclude license comments, which often
            # begin with a line of stars.
            is_doc_comment = segment =~ /\A\/\*\*[^*]/

            is_starred = segment =~ /
              \A
              \/\*.*(\n|$)           # first line
              (^[ \t]*\*.*(\n|$))*   # remaining lines
              \z
            /x

            is_first_line_empty = segment =~ /\A\/\*\*?[ \t]*$/

            # Remove delimiters and associated whitespace & newline.
            segment = if is_starred && !is_first_line_empty
              if is_doc_comment
                segment.sub(/\A\/\*/, "")
              else
                segment.sub(/\A\//, "")
              end
            else
              if is_doc_comment
                segment.sub(/\A\/\*\*[ \t]*\n?/, "")
              else
                segment.sub(/\A\/\*[ \t]*\n?/, "")
              end
            end
            segment = segment.sub(/\n?[ \t]*\*\/\z/, "")

            # Prepend "#" delimiters. Handle "starred" comments specially.
            if is_starred
              segment = segment.gsub(/^[ \t]*\*/, "#")
            else
              segment = segment.
                gsub(/^#{Regexp.quote(prefix)}/, "").
                gsub(/^/, "# ")
            end

            # Process doc comments.
            segment = process_doc_comment(node, segment) if is_doc_comment

            segment
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
                if context.whitespace != Comments::Whitespace::DROP_ALL
                  context = context.with_whitespace(Comments::Whitespace::DROP_ALL)
                end

                node = send(name_without_comments, context)
                if node
                  if comment_before
                    processed_comment_before = Comments.process_comment_before(
                      self,
                      comment_before,
                      :whitespace => whitespace
                    )
                    if processed_comment_before
                      node.comment_before = processed_comment_before
                    end
                  end

                  if comment_after
                    processed_comment_after = Comments.process_comment_after(
                      self,
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

        def remove_duplicate_imports(statements)
          seen_imports = []

          statements.select do |statement|
            if statement.is_a?(Import)
              if seen_imports.include?(statement.name)
                false
              else
                seen_imports << statement.name
                true
              end
            else
              true
            end
          end
        end

        def compile_statements_with_whitespace(statements, context)
          # There is a duplicate import removal logic in ycpc, but it doesn't
          # work for auto-iports such as UI. As a result, we need to do the
          # deduplication again ourselves.
          statements = remove_duplicate_imports(statements)

          case statements.size
            when 0
              []

            when 1
              statement_context = context.with_whitespace(Comments::Whitespace.new(
                :drop_before_above => true,
                :drop_after_below  => true
              ))

              [statements.first.compile(statement_context)]
            else
              first_context  = context.with_whitespace(Comments::Whitespace.new(
                :drop_before_above => true
              ))
              middle_context = context.with_whitespace(Comments::Whitespace::KEEP_ALL)
              last_context   = context.with_whitespace(Comments::Whitespace.new(
                :drop_after_below => true
              ))

              [statements.first.compile(first_context)] +
                statements[1..-2].map { |s| s.compile(middle_context) } +
                [statements.last.compile(last_context)]
            end
        end

        def optimize_last_statement(statements, klass)
          if !statements.empty?
            last = statements.last

            last_optimized = if last.is_a?(klass)
              value = last.value || Ruby::Literal.new(:value => nil)

              # We can't optimize the |return| or |next| away if they have
              # comments and we can't move them to the value because it has its
              # own comments. (We don't want to mess with concatenating.)
              can_optimize = true
              can_optimize = false if last.comment_before && value.comment_before
              can_optimize = false if last.comment_after  && value.comment_after

              if can_optimize
                value.comment_before = last.comment_before if last.comment_before
                value.comment_after  = last.comment_after  if last.comment_after
                value
              else
                last
              end
            else
              last
            end

            statements[0..-2] + [last_optimized]
          else
            []
          end
        end

        def optimize_return(statements)
          optimize_last_statement(statements, Ruby::Return)
        end

        def optimize_next(statements)
          optimize_last_statement(statements, Ruby::Next)
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
            :name     => "set",
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
          case context.innermost(While, Do, Repeat, UnspecBlock, Case, Default)
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
            when Case
              raise NotImplementedError,
                  "Case with a break in the middle encountered. These are not supported."
            when Default
              raise NotImplementedError,
                  "Default with a break in the middle encountered. These are not supported."
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

            case result
              when :used
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

              when :unused
                Ruby::Statements.new(
                  :statements => [
                    *setters,
                    call,
                    *getters,
                  ]
                )

              else
                raise "Unknown call result usage flag: #{result.inspect}."
            end

          else
            call
          end
        end

        transfers_comments :compile
      end

      class Case < Node
        def symbols
          []
        end

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

          context.inside self do |inner_context|
            Ruby::When.new(
              :values => values.map { |v| v.compile(inner_context) },
              :body   => body_without_break.compile(inner_context)
            )
          end
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
        def symbols
          []
        end

        def compile(context)
          if body.statements.last.is_a?(Break)
            # The following dance is here because we want ot keep the AST nodes
            # immutable and thus avoid modifying their data.

            body_without_break = body.dup
            body_without_break.statements = body.statements[0..-2]
          else
            body_without_break = body
          end

          context.inside self do |inner_context|
            Ruby::Else.new(:body => body_without_break.compile(inner_context))
          end
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
            Ruby::Statements.new(
              :statements => optimize_return(
                compile_statements_with_whitespace(statements, inner_context)
              )
            )
          end
        end

        def always_returns?
          statements.any? { |s| s.always_returns? }
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
            class_statements += build_main_def(inner_context)
            class_statements += build_other_defs(inner_context)
          end

          Ruby::Program.new(
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

        def has_main_def?
          !other_statements.empty?
        end

        def build_main_def(context)
          if has_main_def?
            main_statements = compile_statements_with_whitespace(
              other_statements,
              context
            )

            unless other_statements.any? {|s| s.always_returns? }
              main_statements << Ruby::Literal.new(
                :value          => nil,
                :comment_before => ""
              )
            end

            [
              Ruby::Def.new(
                :name       => "main",
                :args       => [],
                :statements => Ruby::Statements.new(
                  :statements => optimize_return(main_statements)
                )
              )
            ]
          else
            []
          end
        end

        def build_other_defs(context)
          defs = compile_statements_with_whitespace(fundef_statements, context)

          unless defs.empty?
            defs.first.ensure_separated if has_main_def?
          end

          defs
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
              statements.statements << Ruby::Literal.new(
                :value          => nil,
                :comment_before => ""
              )
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
          then_context = context.disable_elsif
          then_compiled = compile_statements(self.then, then_context)

          if self.else
            else_context = if self.else.is_a?(If)
              context.enable_elsif
            else
              context.disable_elsif
            end
            else_compiled = compile_statements(self.else, else_context)
          else
            else_compiled = nil
          end

          Ruby::If.new(
            :condition => cond.compile(context),
            :then      => then_compiled,
            :else      => else_compiled,
            :elsif     => !!context.elsif_mode
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
            :parens   => false
          )
        end

        transfers_comments :compile
      end

      class Include < Node
        def compile(context)
          if !context.at_toplevel?
            raise NotImplementedError,
                  "Non-toplevel includes are not supported."
          end

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
            :parens   => false
          )
        end

        transfers_comments :compile
      end

      class IncludeBlock < Node
        def compile(context)
          class_statements = []

          context.inside self do |inner_context|
            class_statements += build_initialize_method_def(inner_context)
            class_statements += build_other_defs(inner_context)
          end

          Ruby::Program.new(
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

        def has_initialize_method_def?
          !other_statements.empty?
        end

        def build_initialize_method_def(context)
          if has_initialize_method_def?
            initialize_method_statements = compile_statements_with_whitespace(
              other_statements,
              context
            )

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
          defs = compile_statements_with_whitespace(fundef_statements, context)

          unless defs.empty?
            defs.first.ensure_separated if has_initialize_method_def?
          end

          defs
        end
      end

      class List < Node
        def compile(context)
          Ruby::Array.new(
            :elements => children.map { |ch| ch.compile(context) }
          )
        end

        transfers_comments :compile

        def empty?
          children.empty?
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

        def empty?
          children.empty?
        end
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
            :statements => Ruby::Statements.new(
              :statements => [
                Ruby::MethodCall.new(
                  :receiver => nil,
                  :name     => "require",
                  :args     => [Ruby::Literal.new(:value => "yast")],
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
            main_statements = compile_statements_with_whitespace(
              other_statements,
              context
            )

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
          defs = compile_statements_with_whitespace(fundef_statements, context)

          unless defs.empty?
            defs.first.ensure_separated if has_main_def?
          end

          defs
        end

        def build_publish_calls(context)
          exported_symbols = if context.options[:export_private]
            symbols
          else
            symbols.select(&:global)
          end

          calls = exported_symbols.map { |s| s.compile_as_publish_call(context) }

          unless calls.empty?
            if has_main_def? || !fundef_statements.empty?
              calls.first.ensure_separated
            end
          end

          calls
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
            Ruby::Statements.new(
              :statements => compile_statements_with_whitespace(
                statements,
                inner_context
              )
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
          args = [
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
            args << Ruby::HashEntry.new(
              :key   => Ruby::Literal.new(:value => :private),
              :value => Ruby::Literal.new(:value => true)
            )
          end

          Ruby::MethodCall.new(
            :receiver => nil,
            :name     => "publish",
            :args     => args,
            :block    => nil,
            :parens   => false
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
                  :statements => optimize_next(
                    statements.map { |s| s.compile(inner_context) }
                  )
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
                :statements => optimize_next(
                  statements.map { |s| s.compile(inner_context) }
                )
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

      # Forward declaration needed for |YEBracket::LAZY_DEFULT_CLASSES|.
      class YETerm < Node
      end

      class YEBracket < Node
        def compile(context)
          args, block = build_args_and_block(context)

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "get",
            :args     => args,
            :block    => block,
            :parens   => true
          )
        end

        def compile_as_shortcut(type, context)
          args, block = build_args_and_block(context)

          Ruby::MethodCall.new(
            :receiver => Ruby::Variable.new(:name => "Ops"),
            :name     => "get_#{type}",
            :args     => args,
            :block    => block,
            :parens   => true
          )
        end

        transfers_comments :compile

        private

        def evaluate_default_lazily?
          is_call           = default.is_a?(Call)
          is_non_empty_list = default.is_a?(List)   && !default.empty?
          is_non_empty_map  = default.is_a?(Map)    && !default.empty?
          is_non_empty_term = default.is_a?(YETerm) && !default.empty?

          is_call || is_non_empty_list || is_non_empty_map || is_non_empty_term
        end

        def build_index(context)
          if index.children.size == 1
            index.children.first.compile(context)
          else
            index.compile(context)
          end
        end

        def build_args_and_block(context)
          # In expressions like |m["foo"]:f()|, the |f| function is called only
          # when the value is missing. In other words, the default is evaluated
          # lazily. We need to emulate this laziness for calls and all
          # expressions that can contain them.
          if evaluate_default_lazily?
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

          [args, block]
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
        # Needs to be in sync with |Yast::Ops::SHORTCUT_TYPES| in Ruby bindings.
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
              if child.is_a?(YEBracket)
                child.compile_as_shortcut(to.no_const, context)
              else
                Ruby::MethodCall.new(
                  :receiver => Ruby::Variable.new(:name => "Convert"),
                  :name     => "to_#{to.no_const}",
                  :args     => [child.compile(context)],
                  :block    => nil,
                  :parens   => true
                )
              end
            else
              Ruby::MethodCall.new(
                :receiver => Ruby::Variable.new(:name => "Convert"),
                :name     => "convert",
                :args     => [
                  child.compile(context),
                  Ruby::HashEntry.new(
                    :key   => Ruby::Literal.new(:value => :from),
                    :value => Ruby::Literal.new(:value => from.no_const.to_s)
                  ),
                  Ruby::HashEntry.new(
                    :key   => Ruby::Literal.new(:value => :to),
                    :value => Ruby::Literal.new(:value => to.no_const.to_s)
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

        def empty?
          children.empty?
        end
      end

      class YETriple < Node
        def compile_as_copy_if_needed(context)
          Ruby::TernaryOperator.new(
            :condition => cond.compile(context),
            :then      => self.true.compile_as_copy_if_needed(context),
            :else      => self.false.compile_as_copy_if_needed(context)
          )
        end

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
