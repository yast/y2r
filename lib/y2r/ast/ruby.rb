# encoding: utf-8

require "ostruct"

module Y2R
  module AST
    # Classes in this module represent Ruby AST nodes. Their main task is to
    # serialize themselves into readable Ruby code using the |to_ruby| method.
    #
    # Note that these classes can't represent the whole Ruby language, only
    # parts actually generated by Y2R.
    module Ruby
      # Context passed to the #to_ruby and related methods on nodes.
      class Context < OpenStruct
        def indented(n)
          context = dup
          context.width -= n
          context
        end
      end

      class Node < OpenStruct
        INDENT_STEP = 2

        def to_ruby_enclosed(context)
          enclose? ? "(#{to_ruby(context.indented(1))})" : to_ruby(context)
        end

        protected

        def indented(node, context)
          indent(node.to_ruby(context.indented(INDENT_STEP)))
        end

        def indent(s)
          s.gsub(/^(?=.)/, " " * INDENT_STEP)
        end

        def combine
          parts = []
          yield parts
          parts.join("\n")
        end

        def list(items, separator, context)
          item_indent = 0
          items.map do |item|
            item_code = item.to_ruby(context.indented(item_indent))
            item_indent += item_code.size + separator.size
            item_code
          end.join(separator)
        end

        def enclose?
          true
        end
      end

      # ===== Statements =====

      class Program < Node
        def to_ruby(context)
          combine do |parts|
            parts << "# encoding: utf-8"
            parts << "# #{comment}" if comment
            parts << ""
            parts << statements.to_ruby(context)
          end
        end
      end

      class Class < Node
        def to_ruby(context)
          superclass_indent  = 6 + name.size + 3
          superclass_context = context.indented(superclass_indent)
          superclass_code    = superclass.to_ruby(superclass_context)

          combine do |parts|
            parts << "class #{name} < #{superclass_code}"
            parts << indented(statements, context)
            parts << "end"
          end
        end
      end

      class Module < Node
        def to_ruby(context)
          combine do |parts|
            parts << "module #{name}"
            parts << indented(statements, context)
            parts << "end"
          end
        end
      end

      class Def < Node
        def to_ruby(context)
          args_indent  = 4 + name.size + 1
          args_context = context.indented(args_indent)
          args_code    = if !args.empty?
            "(#{list(args, ", ", args_context)})"
          else
            ""
          end

          combine do |parts|
            parts << "def #{name}#{args_code}"
            parts << indented(statements, context)
            parts << "end"
          end
        end
      end

      class Statements < Node
        def to_ruby(context)
          combine do |parts|
            # The |compact| call is needed because some YCP AST nodes don't
            # translate into anything, meaning their |compile| method will
            # return |nil|. These |nil|s may end up in statement lists.
            statements.compact.each { |s| parts << s.to_ruby(context) }
          end
        end
      end

      class Begin < Node
        def to_ruby(context)
          combine do |parts|
            parts << "begin"
            parts << indented(statements, context)
            parts << "end"
          end
        end
      end

      # TODO: Use trailing form where it makes sense.
      class If < Node
        def to_ruby(context)
          combine do |parts|
            parts << "if #{condition.to_ruby(context.indented(3))}"
            parts << indented(self.then, context)
            if self.else
              parts << "else"
              parts << indented(self.else, context)
            end
            parts << "end"
          end
        end
      end

      # TODO: Use trailing form where it makes sense.
      class Unless < Node
        def to_ruby(context)
          combine do |parts|
            parts << "unless #{condition.to_ruby(context.indented(7))}"
            parts << indented(self.then, context)
            if self.else
              parts << "else"
              parts << indented(self.else, context)
            end
            parts << "end"
          end
        end
      end

      class Case < Node
        def to_ruby(context)
          combine do |parts|
            parts << "case #{expression.to_ruby(context.indented(5))}"
            whens.each do |whem|
              parts << indented(whem, context)
            end
            parts << indented(self.else, context) if self.else
            parts << "end"
          end
        end
      end

      class When < Node
        def to_ruby(context)
          values_indent  = 5
          values_context = context.indented(values_indent)

          combine do |parts|
            parts << "when #{list(values, ", ", values_context)}"
            parts << indented(body, context)
          end
        end
      end

      class Else < Node
        def to_ruby(context)
          combine do |parts|
            parts << "else"
            parts << indented(body, context)
          end
        end
      end

      class While < Node
        def to_ruby(context)
          if !body.is_a?(Begin)
            combine do |parts|
              parts << "while #{condition.to_ruby(context.indented(6))}"
              parts << indented(body, context)
              parts << "end"
            end
          else
            "#{body.to_ruby(context)} while #{condition.to_ruby(context)}"
          end
        end
      end

      class Until < Node
        def to_ruby(context)
          if !body.is_a?(Begin)
            combine do |parts|
              parts << "until #{condition.to_ruby(context.indented(6))}"
              parts << indented(body, context)
              parts << "end"
            end
          else
            "#{body.to_ruby(context)} until #{condition.to_ruby(context)}"
          end
        end
      end

      class Break < Node
        def to_ruby(context)
          "break"
        end
      end

      class Next < Node
        def to_ruby(context)
          "next" + (value ? " #{value.to_ruby(context.indented(5))}" : "")
        end
      end

      class Return < Node
        def to_ruby(context)
          "return" + (value ? " #{value.to_ruby(context.indented(7))}" : "")
        end
      end

      # ===== Expressions =====

      # TODO: Use parens only when needed.
      class Expressions < Node
        def to_ruby(context)
          expressions_indent  = 1
          expressions_context = context.indented(expressions_indent)

          "(#{list(expressions, "; ", expressions_context)})"
        end
      end

      class Assignment < Node
        def to_ruby(context)
          lhs_code   = lhs.to_ruby(context)
          # YCP always makes a copy when assigning.
          if rhs.is_a?(Variable)
            rhs_indent  = lhs_code.size + 13
            rhs_context = context.indented(rhs_indent)
            rhs_code    = "deep_copy(#{rhs.to_ruby(rhs_context)})"
          else
            rhs_indent  = lhs_code.size + 3
            rhs_context = context.indented(rhs_indent)
            rhs_code    = rhs.to_ruby(rhs_context)
          end

          "#{lhs_code} = #{rhs_code}"
        end
      end

      # TODO: Use parens only when needed.
      class UnaryOperator < Node
        def to_ruby(context)
          "#{op}#{expression.to_ruby_enclosed(context.indented(op.size))}"
        end

        protected

        def enclose?
          false
        end
      end

      # TODO: Use parens only when needed.
      class BinaryOperator < Node
        def to_ruby(context)
          lhs_code    = lhs.to_ruby_enclosed(context)
          rhs_indent  = lhs_code.size + 1 + op.size + 1
          rhs_context = context.indented(rhs_indent)
          rhs_code    = rhs.to_ruby_enclosed(rhs_context)

          "#{lhs_code} #{op} #{rhs_code}"
        end
      end

      class TernaryOperator < Node
        def to_ruby(context)
          condition_code = condition.to_ruby_enclosed(context)
          then_indent    = condition_code.size + 3
          then_context   = context.indented(then_indent)
          then_code      = self.then.to_ruby_enclosed(then_context)
          else_indent    = then_indent + then_code.size + 3
          else_context   = context.indented(else_indent)
          else_code      = self.else.to_ruby_enclosed(else_context)

          "#{condition_code} ? #{then_code} : #{else_code}"
        end
      end

      # TODO: Split to multiple lines if any argument is multiline.
      # TODO: Split to multiple lines if the result is too long.
      # TODO: Handle hash as the last argument specially.
      class MethodCall < Node
        def to_ruby(context)
          receiver_code = receiver ? "#{receiver.to_ruby(context)}." : ""

          args_code = if !args.empty?
            if parens
              "(#{list(args, ", ", context)})"
            else
              " #{list(args, ", ", context)}"
            end
          else
            !receiver && name =~ /^[A-Z]/ && args.empty? ? "()" : ""
          end

          block_code = block ? " #{block.to_ruby(context)}" : ""

          "#{receiver_code}#{name}#{args_code}#{block_code}"
        end

        protected

        def enclose?
          !parens
        end
      end

      # TODO: Emit one-line blocks for one-line block bodies.
      class Block < Node
        def to_ruby(context)
          args_indent  = 3
          args_context = context.indented(args_indent)
          args_code    = if !args.empty?
            " |#{list(args, ", ", args_context)}|"
          else
            ""
          end

          combine do |parts|
            parts << "{#{args_code}"
            parts << indented(statements, context)
            parts << "}"
          end
        end
      end

      class ConstAccess < Node
        def to_ruby(context)
          (receiver ? "#{receiver.to_ruby(context)}::" : "") + name
        end

        protected

        def enclose?
          false
        end
      end

      class Variable < Node
        def to_ruby(context)
          name
        end

        protected

        def enclose?
          false
        end
      end

      class Self < Node
        def to_ruby(context)
          "self"
        end

        protected

        def enclose?
          false
        end
      end

      # ===== Literals =====

      class Literal < Node
        def to_ruby(context)
          value.inspect
        end

        protected

        def enclose?
          false
        end
      end

      class Array < Node
        # TODO: Split to multiple lines if any element is multiline.
        # TODO: Split to multiple lines if the result is too long.
        def to_ruby(context)
          elements_indent  = 1
          elements_context = context.indented(elements_indent)

          "[#{list(elements, ", ", elements_context)}]"
        end

        protected

        def enclose?
          false
        end
      end

      class Hash < Node
        # TODO: Split to multiple lines if any value is multiline.
        # TODO: Split to multiple lines if the result is too long.
        def to_ruby(context)
          entries_indent  = 2
          entries_context = context.indented(entries_indent)

          !entries.empty? ? "{ #{list(entries, ", ", entries_context)} }" : "{}"
        end

        protected

        def enclose?
          false
        end
      end

      class HashEntry < Node
        def to_ruby(context)
          key_code      = key.to_ruby_enclosed(context)
          value_indent  = key_code.size + 4
          value_context = context.indented(value_indent)
          value_code    = value.to_ruby_enclosed(value_context)

          "#{key_code} => #{value_code}"
        end

        protected

        def enclose?
          false
        end
      end
    end
  end
end
