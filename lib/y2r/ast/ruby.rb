require "ostruct"

module Y2R
  module AST
    # Classes in this module represent Ruby AST nodes. Their main task is to
    # serialize themselves into readable Ruby code using the |to_ruby| method.
    #
    # Note that these classes can't represent the whole Ruby language, only
    # parts actually generated by Y2R.
    module Ruby
      class Node < OpenStruct
        protected

        def indent(s)
          s.gsub(/^(?=.)/, "  ")
        end

        def combine
          parts = []
          yield parts
          parts.join("\n")
        end

        def list(items)
          items.map(&:to_ruby).join(", ")
        end
      end

      # ===== Statements =====

      class Program < Node
        def to_ruby
          combine do |parts|
            parts << "# encoding: utf-8"
            parts << ""
            parts << statements.to_ruby
          end
        end
      end

      class Class < Node
        def to_ruby
          combine do |parts|
            parts << "class #{name}"
            parts << indent(statements.to_ruby)
            parts << "end"
          end
        end
      end

      class Module < Node
        def to_ruby
          combine do |parts|
            parts << "module #{name}"
            parts << indent(statements.to_ruby)
            parts << "end"
          end
        end
      end

      class Def < Node
        def to_ruby
          combine do |parts|
            parts << "def #{name}" + (!args.empty? ? "(#{list(args)})" : "")
            parts << indent(statements.to_ruby)
            parts << "end"
          end
        end
      end

      class Arg < Node
        def to_ruby
          name
        end
      end

      class Statements < Node
        def to_ruby
          combine do |parts|
            # The |compact| call is needed because some YCP AST nodes don't
            # translate into anything, meaning their |compile| method will
            # return |nil|. These |nil|s may end up in statement lists.
            statements.compact.each { |s| parts << s.to_ruby }
          end
        end
      end

      class Begin < Node
        def to_ruby
          combine do |parts|
            parts << "begin"
            parts << indent(statements.to_ruby)
            parts << "end"
          end
        end
      end

      # TODO: Use trailing form where it makes sense.
      class If < Node
        def to_ruby
          combine do |parts|
            parts << "if #{condition.to_ruby}"
            parts << indent(self.then.to_ruby)
            if self.else
              parts << "else"
              parts << indent(self.else.to_ruby)
            end
            parts << "end"
          end
        end
      end

      # TODO: Use trailing form where it makes sense.
      class Unless < Node
        def to_ruby
          combine do |parts|
            parts << "unless #{condition.to_ruby}"
            parts << indent(self.then.to_ruby)
            if self.else
              parts << "else"
              parts << indent(self.else.to_ruby)
            end
            parts << "end"
          end
        end
      end

      class Case < Node
        def to_ruby
          combine do |parts|
            parts << "case #{expression.to_ruby}"
            whens.each do |whem|
              parts << indent(whem.to_ruby)
            end
            parts << indent(self.else.to_ruby) if self.else
            parts << "end"
          end
        end
      end

      class When < Node
        def to_ruby
          combine do |parts|
            parts << "when #{list(values)}"
            parts << indent(self.body.to_ruby)
          end
        end
      end

      class Else < Node
        def to_ruby
          combine do |parts|
            parts << "else"
            parts << indent(self.body.to_ruby)
          end
        end
      end

      class While < Node
        def to_ruby
          if !body.is_a?(Begin)
            combine do |parts|
              parts << "while #{condition.to_ruby}"
              parts << indent(body.to_ruby)
              parts << "end"
            end
          else
            "#{body.to_ruby} while #{condition.to_ruby}"
          end
        end
      end

      class Until < Node
        def to_ruby
          if !body.is_a?(Begin)
            combine do |parts|
              parts << "until #{condition.to_ruby}"
              parts << indent(body.to_ruby)
              parts << "end"
            end
          else
            "#{body.to_ruby} until #{condition.to_ruby}"
          end
        end
      end

      class Break < Node
        def to_ruby
          "break"
        end
      end

      class Next < Node
        def to_ruby
          "next" + (value ? " #{value.to_ruby}" : "")
        end
      end

      class Return < Node
        def to_ruby
          "return" + (value ? " #{value.to_ruby}" : "")
        end
      end

      # ===== Expressions =====

      class Assignment < Node
        def to_ruby
          "#{lhs.to_ruby} = #{rhs.to_ruby}"
        end
      end

      class UnaryOperator < Node
        def to_ruby
          "#{ops}(#{child.to_ruby})"
        end
      end

      class BinaryOperator < Node
        def to_ruby
          "(#{lhs.to_ruby}) #{ops} (#{rhs.to_ruby})"
        end
      end

      class Ternary < Node
        def to_ruby
          "#{condition.to_ruby} ? #{self.then.to_ruby} : #{self.else.to_ruby}"
        end
      end

      # TODO: Split to multiple lines if any argument is multiline.
      # TODO: Split to multiple lines if the result is too long.
      # TODO: Handle hash as the last argument specially.
      class MethodCall < Node
        def to_ruby
          receiver_code = receiver ? "#{receiver.to_ruby}." : ""

          args_code = if !args.empty?
            parens ? "(#{list(args)})" : " #{list(args)}"
          else
            !receiver && name =~ /^[A-Z]/ && args.empty? ? "()" : ""
          end

          block_code = block ? " #{block.to_ruby}" : ""

          "#{receiver_code}#{name}#{args_code}#{block_code}"
        end
      end

      # TODO: Emit one-line blocks for one-line block bodies.
      class Block < Node
        def to_ruby
          combine do |parts|
            parts << "{" + (!args.empty? ? " |#{list(args)}|" : "")
            parts << indent(statements.to_ruby)
            parts << "}"
          end
        end
      end

      class ConstAccess < Node
        def to_ruby
          (receiver ? "#{receiver.to_ruby}::" : "") + name
        end
      end

      class Variable < Node
        def to_ruby
          name
        end
      end

      class Self < Node
        def to_ruby
          "self"
        end
      end

      # ===== Literals =====

      class Literal < Node
        def to_ruby
          value.inspect
        end
      end

      class Array < Node
        # TODO: Split to multiple lines if any element is multiline.
        # TODO: Split to multiple lines if the result is too long.
        def to_ruby
          "[#{list(elements)}]"
        end
      end

      class Hash < Node
        # TODO: Split to multiple lines if any value is multiline.
        # TODO: Split to multiple lines if the result is too long.
        def to_ruby
          !entries.empty? ? "{ #{list(entries)} }" : "{}"
        end
      end

      class HashEntry < Node
        def to_ruby
          "#{key.to_ruby} => #{value.to_ruby}"
        end
      end
    end
  end
end
