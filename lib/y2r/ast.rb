require "ostruct"

module Y2R
  module AST
    # Sorted alphabetically.

    class Args < OpenStruct
      def to_ruby
        children.map(&:to_ruby).join(", ")
      end
    end

    class Assign < OpenStruct
      def to_ruby
        "#{name} = #{child.to_ruby}"
      end
    end

    class Block < OpenStruct
      def to_ruby
        statements.to_ruby
      end
    end

    class Builtin < OpenStruct
      def to_ruby
        "YCP::Builtins.#{name}(" + children.map(&:to_ruby).join(", ") + ")"
      end
    end

    class BuiltinElement < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class Call < OpenStruct
      def to_ruby
        # TODO: YCP uses call-by-value.
        "#{ns}.#{name}(#{child ? child.to_ruby : ""})"
      end
    end

    class Const < OpenStruct
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
            "YCP::Path.new('#{value}')" # TODO: Implement escaping.
          else
            raise "Unknown const type: #{type}."
        end
      end
    end

    class Expr < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class Import < OpenStruct
      def to_ruby
        "YCP.import('#{name}')" # TODO: Implement escaping.
      end
    end

    class Key < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class List < OpenStruct
      def to_ruby
        "[" + children.map(&:to_ruby).join(", ") + "]"
      end
    end

    class ListElement < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class Map < OpenStruct
      def to_ruby
        if !children.empty?
          "{ " + children.map(&:to_ruby).join(", ") + " }"
        else
          "{}"
        end
      end
    end

    class MapElement < OpenStruct
      def to_ruby
        "#{key.to_ruby} => #{value.to_ruby}"
      end
    end

    class Statements < OpenStruct
      def to_ruby
        children.map(&:to_ruby).join("\n")
      end
    end

    class Stmt < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class Symbol < OpenStruct
      def to_ruby
        return ""
      end
    end

    class Symbols < OpenStruct
      def to_ruby
        children.map(&:to_ruby).join("")
      end
    end

    class Value < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class YCP < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end

    class YETerm < OpenStruct
      def to_ruby
        # TODO: Implement escaping.
        if !children.empty?
          "YCP::Term.new(:#{name}, " + children.map(&:to_ruby).join(", ") + ")"
        else
          "YCP::Term.new(:#{name})"
        end
      end
    end

    class YETermElement < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end
  end
end
