require "ostruct"

module Y2R
  module AST
    class Node < OpenStruct
      def indent(s)
        s.gsub(/^/, "  ")
      end
    end

    class Context
      attr_accessor :blocks

      def initialize(attrs = {})
        @blocks = attrs[:blocks] || []
      end

      def in_function?
        @blocks.include?(:def)
      end
    end

    # Sorted alphabetically.

    class Assign < Node
      def to_ruby(context = Context.new)
        "#{name} = #{child.to_ruby(context)}"
      end
    end

    class Block < Node
      def to_ruby(context = Context.new)
        statements_context = context.dup
        statements_context.blocks = statements_context.blocks + [kind]

        case kind
          when :def, :file
            statements.map { |s| s.to_ruby(statements_context) }.join("\n")
          when :stmt
            raise NotImplementedError, "Statement blocks are not supported."
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
        [
          "{ |" + args.join(", ") + "|",
          indent(statements.map { |s| s.to_ruby(statements_context) }.join("\n")),
          "}"
        ].join("\n")
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
            ":#{value}" # TODO: Implement escaping.
          when :string
            "'#{value}'" # TODO: Implement escaping.
          when :path
            "Path.new('#{value}')" # TODO: Implement escaping.
          else
            raise "Unknown const type: #{type}."
        end
      end
    end

    class FunDef < Node
      def to_ruby(context = Context.new)
        if context.in_function?
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
          "YCP.import('#{name}')", # TODO: Implement escaping.
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
        "_('" + text + "')"
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
        if child
          "return #{child.to_ruby(context)}"
        else
          "return"
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
          "FastGettext.text_domain = '#{name}'", # TODO: Implement escaping.
          ""
        ].join("\n")
      end
    end

    class Variable < Node
      def to_ruby(context = Context.new)
        name
      end
    end

    class While < Node
      def to_ruby(context = Context.new)
        [
          "while #{cond.to_ruby(context)}",
          indent(self.do.to_ruby(context)),
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

    class YEReturn < Node
      def to_ruby(context = Context.new)
        "lambda { #{child.to_ruby(context)} }"
      end
    end

    class YETerm < Node
      def to_ruby(context = Context.new)
        # TODO: Implement escaping.
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
