require "ostruct"

module Y2R
  module AST
    # Sorted alphabetically.

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

    class YCP < OpenStruct
      def to_ruby
        child.to_ruby
      end
    end
  end
end
