require "ostruct"

module Y2R
  module AST
    class Node < OpenStruct
      def indent(s)
        s.gsub(/^/, "  ")
      end
    end

    # Sorted alphabetically.

    class Assign < Node
      def to_ruby
        "#{name} = #{child.to_ruby}"
      end
    end

    class Block < Node
      def to_ruby
        case kind
          when :def, :file, :stmt
            statements.map(&:to_ruby).join("\n")
          when :unspec
            symbols.map(&:to_ruby).join(", ")
          else
            raise "Unknown block kind: #{kind}."
        end
      end
    end

    class Builtin < Node
      def to_ruby
        "Builtins.#{name}(" + children.map(&:to_ruby).join(", ") + ")"
      end
    end

    class Call < Node
      def to_ruby
        # TODO: YCP uses call-by-value.
        "#{ns}.#{name}(#{args.map(&:to_ruby).join(", ")})"
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

      def to_ruby
        "Ops.#{OPS_TO_METHODS[op]}(#{lhs.to_ruby}, #{rhs.to_ruby})"
      end
    end

    class Const < Node
      def to_ruby
        case type
          when "void"
            "nil"
          when "bool", "int"
            value
          when "float"
            value.sub(/\.$/, ".0")
          when "symbol"
            ":#{value}" # TODO: Implement escaping.
          when "string"
            "'#{value}'" # TODO: Implement escaping.
          when "path"
            "Path.new('#{value}')" # TODO: Implement escaping.
          else
            raise "Unknown const type: #{type}."
        end
      end
    end

    class FunDef < Node
      def to_ruby
        [
          "def #{name}(#{args.map(&:to_ruby).join(", ")})",
          indent(block.to_ruby),
          "end",
          ""
        ].join("\n")
      end
    end

    class If < Node
      def to_ruby
        if self.else
          [
            "if #{cond.to_ruby}",
            indent(self.then.to_ruby),
            "else",
            indent(self.else.to_ruby),
            "end"
          ].join("\n")
        else
          [
            "if #{cond.to_ruby}",
            indent(self.then.to_ruby),
            "end"
          ].join("\n")
        end
      end
    end

    class Import < Node
      def to_ruby
        [
          "YCP.import('#{name}')", # TODO: Implement escaping.
          ""
        ].join("\n")
      end
    end

    class List < Node
      def to_ruby
        "[" + children.map(&:to_ruby).join(", ") + "]"
      end
    end

    class Locale < Node
      def to_ruby
        "_('" + text + "')"
      end
    end

    class Map < Node
      def to_ruby
        if !children.empty?
          "{ " + children.map(&:to_ruby).join(", ") + " }"
        else
          "{}"
        end
      end
    end

    class MapElement < Node
      def to_ruby
        "#{key.to_ruby} => #{value.to_ruby}"
      end
    end

    class Return < Node
      def to_ruby
        if child
          "return #{child.to_ruby}"
        else
          "return"
        end
      end
    end

    class Symbol < Node
      def to_ruby
        name
      end
    end

    class Textdomain < Node
      def to_ruby
        [
          "FastGettext.text_domain = '#{name}'", # TODO: Implement escaping.
          ""
        ].join("\n")
      end
    end

    class Variable < Node
      def to_ruby
        name
      end
    end

    class While < Node
      def to_ruby
        [
          "while #{cond.to_ruby}",
          indent(self.do.to_ruby),
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

      def to_ruby
        "Ops.#{OPS_TO_METHODS[name]}(#{lhs.to_ruby}, #{rhs.to_ruby})"
      end
    end

    class YEBracket < Node
      def to_ruby
        "Ops.index(#{value.to_ruby}, #{index.to_ruby}, #{default.to_ruby})"
      end
    end

    class YETerm < Node
      def to_ruby
        # TODO: Implement escaping.
        if !children.empty?
          "Term.new(:#{name}, " + children.map(&:to_ruby).join(", ") + ")"
        else
          "Term.new(:#{name})"
        end
      end
    end

    class YETriple < Node
      def to_ruby
        "#{cond.to_ruby} ? #{self.true.to_ruby} : #{self.false.to_ruby}"
      end
    end

    class YEUnary < Node
      OPS_TO_METHODS = {
        "-"  => "unary_minus",
        "~"  => "bitwise_not",
        "!"  => "logical_not"
      }

      def to_ruby
        "Ops.#{OPS_TO_METHODS[name]}(#{child.to_ruby})"
      end
    end
  end
end
