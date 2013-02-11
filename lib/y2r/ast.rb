require "ostruct"

module Y2R
  module AST
    class Node < OpenStruct
      def indent(s)
        s.gsub(/^(?=.)/, "  ")
      end

      # Escapes valid YCP variable names that are not valid Ruby local variable
      # names
      def escape_ruby_local_var_name(name)
        name.gsub(/^[A-Z_]/) { |ch| "_#{ch}" }
      end

      # This method translates a variable name from ycpc's XML into its Ruby
      # counterpart.
      #
      # The biggest issue is that in the XML, all global module variable
      # references are qualified (e.g. "M::i"). This includes references to
      # variables defined in this module. All other variable references are
      # unqualified (e.g "i").
      #
      # Note that Y2R currently supports only local variables (translated as
      # Ruby local variables) and module-level variables (translated as Ruby
      # instance variables).
      def ruby_var_name(name, context)
        if name =~ /^([^:]+)::([^:]+)$/
          $1 == context.module_name ? "@#$2" : name
        else
          if context.innermost(:file, :module, :def) == :module
            "@#{name}"
          else
            escape_ruby_local_var_name(name)
          end
        end
      end
    end

    class Context
      # TODO: Convert |blocks| from a list of symbols to the list of actual
      #       blocks. |module_name| will be just the name of the outermost
      #       block, if it is a module.
      attr_accessor :blocks, :module_name

      def initialize(attrs = {})
        @blocks      = attrs[:blocks] || []
        @module_name = attrs[:module_name]
      end

      def in?(kind)
        @blocks.include?(kind)
      end

      def innermost(*kinds)
        @blocks.reverse.find { |b| kinds.include?(b) }
      end
    end

    # Sorted alphabetically.

    class Assign < Node
      def to_ruby(context = Context.new)
        "#{ruby_var_name(name, context)} = #{child.to_ruby(context)}"
      end
    end

    class Block < Node
      def to_ruby(context = Context.new)
        statements_context = context.dup
        statements_context.blocks = statements_context.blocks + [kind]

        case kind
          when :def, :file, :stmt
            statements.map { |s| s.to_ruby(statements_context) }.join("\n")
          when :module
            statements_context.module_name = name

            assigns = statements.select { |s| s.is_a?(Assign) }
            fundefs = statements.select { |s| s.is_a?(FunDef) }
            other_statements = statements - assigns - fundefs

            parts = [
              "require \"ycp\"",
              "",
              "module YCP",
              "  class #{name}Class",
              "    extend Exportable"
            ]

            unless other_statements.empty?
              parts += [
                "",
                indent(indent(other_statements.map { |s| s.to_ruby(statements_context) }.join("\n"))),
              ]
            end

            unless assigns.empty?
              parts += [
                "",
                "    def initialize",
                indent(indent(indent(assigns.map { |s| s.to_ruby(statements_context) }.join("\n")))),
                "    end"
              ]
            end

            unless fundefs.empty?
              parts += [
                "",
                indent(indent(fundefs.map { |s| s.to_ruby(statements_context) }.join("\n"))),
              ]
            end

            symbols.each do |symbol|
              next unless symbol.global
              next unless symbol.category == :variable || symbol.category == :function

              parts << indent(indent(
                "publish " +
                  ":#{symbol.category} => :#{symbol.name}, " +
                  ":type => \"#{symbol.type}\""
              ))
            end

            parts += [
              "  end",
              "",
              "  #{name} = #{name}Class.new",
              "end"
            ]

            parts.join("\n")
          when :unspec
            [
              "lambda {",
              indent(statements.map { |s| s.to_ruby(statements_context) }.join("\n")),
              "}"
            ].join("\n")
          else
            raise "Unknown block kind: #{kind}."
        end
      end

      def to_ruby_block(args, context = Context.new)
        statements_context = context.dup
        statements_context.blocks = statements_context.blocks + [kind]

        [
          "{ |" + args.join(", ") + "|",
          indent(statements.map { |s| s.to_ruby(statements_context) }.join("\n")),
          "}"
        ].join("\n")
      end
    end

    class Bracket < Node
      def to_ruby(context = Context.new)
        "Ops.assign(" +
          entry.to_ruby(context) +
          ", " +
          arg.to_ruby(context) +
          ", " +
          rhs.to_ruby(context) +
        ")"
      end
    end

    class Break < Node
      def to_ruby(context = Context.new)
        {
          :loop   => "break",
          :unspec => "raise Break"
        }[context.innermost(:loop, :unspec)]
      end
    end

    class Builtin < Node
      def to_ruby(context = Context.new)
        if symbols.empty?
          args  = children
          block = nil
        else
          args  = children[0..-2]
          block = children.last
        end

        "Builtins.#{name}(" +
          args.map { |ch| ch.to_ruby(context) }.join(", ") +
        ")" + if block
          block_args = symbols.map { |s| s.split(" ").last }
          " " + block.to_ruby_block(block_args, context)
        else
          ""
        end
      end
    end

    class Call < Node
      def to_ruby(context = Context.new)
        # TODO: YCP uses call-by-value.
        "#{ns}.#{name}(" +
          args.map { |a| a.to_ruby(context) }.join(", ") +
        ")"
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

      def to_ruby(context = Context.new)
        "Ops.#{OPS_TO_METHODS[op]}(" +
          lhs.to_ruby(context) +
          ", " +
          rhs.to_ruby(context) +
        ")"
      end
    end

    class Const < Node
      def to_ruby(context = Context.new)
        case type
          when :void
            "nil"
          when :bool, :int
            value
          when :float
            value.sub(/\.$/, ".0")
          when :symbol
            ":#{value}"
          when :string
            value.inspect
          when :path
            "Path.new(#{value.inspect})"
          else
            raise "Unknown const type: #{type}."
        end
      end
    end

    class Continue < Node
      def to_ruby(context = Context.new)
        "next"
      end
    end

    class Entry < Node
      def to_ruby(context = Context.new)
        name
      end
    end

    class FunDef < Node
      def to_ruby(context = Context.new)
        if context.in?(:def)
          raise NotImplementedError, "Nested functions are not supported."
        end

        [
          "def #{name}(" +
            args.map { |a| a.to_ruby(context) }.join(", ") +
          ")",
          indent(block.to_ruby(context)),
          "end",
          ""
        ].join("\n")
      end
    end

    class If < Node
      def to_ruby(context = Context.new)
        if self.else
          [
            "if #{cond.to_ruby(context)}",
            indent(self.then.to_ruby(context)),
            "else",
            indent(self.else.to_ruby(context)),
            "end"
          ].join("\n")
        else
          [
            "if #{cond.to_ruby(context)}",
            indent(self.then.to_ruby(context)),
            "end"
          ].join("\n")
        end
      end
    end

    class Import < Node
      def to_ruby(context = Context.new)
        [
          "YCP.import(#{name.inspect})",
          ""
        ].join("\n")
      end
    end

    class List < Node
      def to_ruby(context = Context.new)
        "[" + children.map { |ch| ch.to_ruby(context) }.join(", ") + "]"
      end
    end

    class Locale < Node
      def to_ruby(context = Context.new)
        "_(#{text.inspect})"
      end
    end

    class Map < Node
      def to_ruby(context = Context.new)
        if !children.empty?
          "{ " + children.map { |ch| ch.to_ruby(context) }.join(", ") + " }"
        else
          "{}"
        end
      end
    end

    class MapElement < Node
      def to_ruby(context = Context.new)
        "#{key.to_ruby(context)} => #{value.to_ruby(context)}"
      end
    end

    class Return < Node
      def to_ruby(context = Context.new)
        unless context.in?(:def) || context.in?(:unspec)
          raise NotImplementedError, "The \"return\" statement at client toplevel is not supported."
        end

        stmt = {
          :def    => "return",
          :unspec => "next"
        }[context.innermost(:def, :unspec)]

        if child
          "#{stmt} #{child.to_ruby(context)}"
        else
          stmt
        end
      end
    end

    class Symbol < Node
      def to_ruby(context = Context.new)
        name
      end
    end

    class Textdomain < Node
      def to_ruby(context = Context.new)
        [
          "FastGettext.text_domain = #{name.inspect}",
          ""
        ].join("\n")
      end
    end

    class Variable < Node
      def to_ruby(context = Context.new)
        ruby_var_name(name, context)
      end
    end

    class While < Node
      def to_ruby(context = Context.new)
        do_context = context.dup
        do_context.blocks = do_context.blocks + [:loop]

        [
          "while #{cond.to_ruby(context)}",
          indent(self.do.to_ruby(do_context)),
          "end"
        ].join("\n")
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

      def to_ruby(context = Context.new)
        "Ops.#{OPS_TO_METHODS[name]}(" +
          lhs.to_ruby(context) +
          ", " +
          rhs.to_ruby(context) +
        ")"
      end
    end

    class YEBracket < Node
      def to_ruby(context = Context.new)
        "Ops.index(" +
          value.to_ruby(context) +
          ", " +
          index.to_ruby(context) +
          ", " +
          default.to_ruby(context) +
        ")"
      end
    end

    class YEPropagate < Node
      def to_ruby(context = Context.new)
        from_no_const = from.sub(/^const /, "")
        to_no_const   = to.sub(/^const /, "")

        if from_no_const != to_no_const
          "Convert.convert(" +
            child.to_ruby(context) + ", " +
            ":from => #{from_no_const.inspect}, " +
            ":to => #{to_no_const.inspect}" +
          ")"
        else
          child.to_ruby(context)
        end
      end
    end

    class YEReturn < Node
      def to_ruby(context = Context.new)
        "lambda { #{child.to_ruby(context)} }"
      end

      def to_ruby_block(args, context = Context.new)
        "{ |#{args.join(", ")}| #{child.to_ruby(context)} }"
      end
    end

    class YETerm < Node
      def to_ruby(context = Context.new)
        if !children.empty?
          "Term.new(:#{name}, " +
            children.map { |ch| ch.to_ruby(context) }.join(", ") +
          ")"
        else
          "Term.new(:#{name})"
        end
      end
    end

    class YETriple < Node
      def to_ruby(context = Context.new)
        cond.to_ruby(context) +
        " ? " +
        self.true.to_ruby(context) +
        " : " +
        self.false.to_ruby(context)
      end
    end

    class YEUnary < Node
      OPS_TO_METHODS = {
        "-"  => "unary_minus",
        "~"  => "bitwise_not",
        "!"  => "logical_not"
      }

      def to_ruby(context = Context.new)
        "Ops.#{OPS_TO_METHODS[name]}(#{child.to_ruby(context)})"
      end
    end
  end
end
