require "ostruct"

module Y2R
  module AST
    module SimpleWrapper
      def to_ruby
        child.to_ruby
      end
    end

    class Node < OpenStruct
      def indent(s)
        s.gsub(/^/, "  ")
      end
    end

    # Sorted alphabetically.

    class Args < Node
      def to_ruby
        children.map(&:to_ruby).join(", ")
      end
    end

    class Assign < Node
      def to_ruby
        "#{name} = #{child.to_ruby}"
      end
    end

    class Block < Node
      def to_ruby
        case kind
          when "def","file"
            statements.to_ruby
          when "unspec"
            symbols.to_ruby
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

    class BuiltinElement < Node
      include SimpleWrapper
    end

    class Call < Node
      def to_ruby
        # TODO: YCP uses call-by-value.
        "#{ns}.#{name}(#{child ? child.to_ruby : ""})"
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

    class Cond < Node
      include SimpleWrapper
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

    class Declaration < Node
      include SimpleWrapper
    end

    class Do < Node
      include SimpleWrapper
    end

    class Else < Node
      include SimpleWrapper
    end

    class Expr < Node
      include SimpleWrapper
    end

    class False < Node
      include SimpleWrapper
    end

    class FunDef < Node
      def to_ruby
        [
          "def #{name}(#{declaration ? declaration.to_ruby : ""})",
          indent(block.to_ruby),
          "end"
        ].join("\n")
      end
    end

    class If < Node
      def to_ruby
        if else_
          [
            "if #{cond.to_ruby}",
            indent(then_.to_ruby),
            "else",
            indent(else_.to_ruby),
            "end"
          ].join("\n")
        else
          [
            "if #{cond.to_ruby}",
            indent(then_.to_ruby),
            "end"
          ].join("\n")
        end
      end

      private

      # The If class is built as a collection because the XML it is constructed
      # from is structured that way. Let's define helpers to hide that a bit.
      def cond;  children[0]; end
      def then_; children[1]; end
      def else_; children[2]; end
    end

    class Import < Node
      def to_ruby
        "YCP.import('#{name}')" # TODO: Implement escaping.
      end
    end

    class Key < Node
      include SimpleWrapper
    end

    class Lhs < Node
      include SimpleWrapper
    end

    class List < Node
      def to_ruby
        "[" + children.map(&:to_ruby).join(", ") + "]"
      end
    end

    class ListElement < Node
      include SimpleWrapper
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

    class Rhs < Node
      include SimpleWrapper
    end

    class Statements < Node
      def to_ruby
        children.map(&:to_ruby).join("\n")
      end
    end

    class Stmt < Node
      include SimpleWrapper
    end

    class Symbol < Node
      def to_ruby
        name
      end
    end

    class Symbols < Node
      def to_ruby
        children.map(&:to_ruby).join(", ")
      end
    end

    class Then < Node
      include SimpleWrapper
    end

    class True < Node
      include SimpleWrapper
    end

    class Value < Node
      include SimpleWrapper
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

    class YCP < Node
      include SimpleWrapper
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

      private

      # The YEBinary class is built as a collection because the XML it is
      # constructed from is structured that way. Let's define helpers to hide
      # that a bit.
      def lhs; children[0]; end
      def rhs; children[1]; end
    end

    class YEBracket < Node
      def to_ruby
        "Ops.index(#{value.to_ruby}, #{index.to_ruby}, #{default.to_ruby})"
      end

      # The YEBracket class is built as a collection because the XML it is
      # constructed from is structured that way. Let's define helpers to hide
      # that a bit.
      def value;   children[0]; end
      def index;   children[1]; end
      def default; children[2]; end
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

    class YETermElement < Node
      include SimpleWrapper
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
