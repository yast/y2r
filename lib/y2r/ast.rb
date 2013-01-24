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
        statements.to_ruby
      end
    end

    class Builtin < Node
      def to_ruby
        "YCP::Builtins.#{name}(" + children.map(&:to_ruby).join(", ") + ")"
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
            "YCP::Path.new('#{value}')" # TODO: Implement escaping.
          else
            raise "Unknown const type: #{type}."
        end
      end
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
        return ""
      end
    end

    class Symbols < Node
      def to_ruby
        children.map(&:to_ruby).join("")
      end
    end

    class Then < Node
      include SimpleWrapper
    end

    class Value < Node
      include SimpleWrapper
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

    class YETerm < Node
      def to_ruby
        # TODO: Implement escaping.
        if !children.empty?
          "YCP::Term.new(:#{name}, " + children.map(&:to_ruby).join(", ") + ")"
        else
          "YCP::Term.new(:#{name})"
        end
      end
    end

    class YETermElement < Node
      include SimpleWrapper
    end
  end
end
