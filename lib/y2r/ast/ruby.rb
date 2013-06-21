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
      # Code-related utilities.
      module Code
        class << self
          def multi_line?(code)
            !code.index("\n").nil?
          end
        end
      end

      # Context passed to the #to_ruby and related methods on nodes.
      class EmitterContext < OpenStruct
        def indented(n)
          context = dup
          context.width -= n
          context.shift = 0
          context
        end

        def shifted(n)
          context = dup
          context.shift += n
          context
        end
      end

      class Node < OpenStruct
        INDENT_STEP = 2

        def to_ruby_enclosed(context)
          enclose? ? "(#{to_ruby(context.shifted(1))})" : to_ruby(context)
        end

        def single_line_width_enclosed
          enclose? ? 1 + single_line_width + 1 : single_line_width
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
          item_shift = 0
          items.map do |item|
            item_context = context.shifted(item_shift)
            item_code    = item.to_ruby(item_context)
            item_shift  += item_code.size + separator.size
            item_code
          end.join(separator)
        end

        def wrapped_line_list(items, opener, separator, closer, context)
          combine do |parts|
            parts << opener
            items[0..-2].each do |item|
              parts << "#{indented(item, context)}#{separator}"
            end
            parts << "#{indented(items.last, context)}" unless items.empty?
            parts << closer
          end
        end

        def list_single_line_width(items, separator_width)
          items_width      = items.map(&:single_line_width).reduce(0, &:+)
          separators_width = separator_width * [items.size - 1, 0].max

          items_width + separators_width
        end

        def fits_current_line?(context)
          single_line_width <= context.width - context.shift
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
            if comment
              parts << ""
              parts << format_comment
            end
            parts << ""
            parts << statements.to_ruby(context)
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
        end

        private

        def format_comment
          comment.gsub(/^.*$/) { |s| s.empty? ? "#" : "# #{s}" }
        end
      end

      class Class < Node
        def to_ruby(context)
          superclass_shift  = 6 + name.size + 3
          superclass_context = context.shifted(superclass_shift)
          superclass_code    = superclass.to_ruby(superclass_context)

          combine do |parts|
            parts << "class #{name} < #{superclass_code}"
            parts << indented(statements, context)
            parts << "end"
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
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

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class Def < Node
        def to_ruby(context)
          args_shift   = 4 + name.size + 1
          args_context = context.shifted(args_shift)
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

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class Statements < Node
        def to_ruby(context)
          combine do |parts|
            # The |compact| call is needed because some YCP AST nodes don't
            # translate into anything, meaning their |compile| method will
            # return |nil|. These |nil|s may end up in statement lists.
            statements.compact.each_with_index do |statement, i|
              parts << statement.to_ruby(context)

              # Yes, this is ugly, but still the best way I can think of now.
              if (statement.is_a?(Def) && statements[i + 1]) ||
                 (statement            && statements[i + 1].is_a?(Def))
                parts << ""
              end
            end
          end
        end

        def single_line_width
          case statements.size
            when 0
              0
            when 1
              statements.first.single_line_width
            else
              Float::INFINITY   # always multiline
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

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class If < Node
        def to_ruby(context)
          if fits_current_line?(context)
            to_ruby_single_line(context)
          else
            to_ruby_multi_line(context)
          end
        end

        def single_line_width
          if !self.else
            self.then.single_line_width + 4 + condition.single_line_width
          else
            Float::INFINITY
          end
        end

        private

        def to_ruby_single_line(context)
          then_code = self.then.to_ruby(context)

          condition_shift   = then_code.size + 4
          condition_context = context.shifted(condition_shift)
          condition_code    = condition.to_ruby(condition_context)

          "#{then_code} if #{condition_code}"
        end

        def to_ruby_multi_line(context)
          combine do |parts|
            parts << "if #{condition.to_ruby(context.shifted(3))}"
            parts << indented(self.then, context)
            if self.else
              parts << "else"
              parts << indented(self.else, context)
            end
            parts << "end"
          end
        end
      end

      class Unless < Node
        def to_ruby(context)
          if fits_current_line?(context)
            to_ruby_single_line(context)
          else
            to_ruby_multi_line(context)
          end
        end

        def single_line_width
          if !self.else
            self.then.single_line_width + 8 + condition.single_line_width
          else
            Float::INFINITY
          end
        end

        private

        def to_ruby_single_line(context)
          then_code = self.then.to_ruby(context)

          condition_shift   = then_code.size + 8
          condition_context = context.shifted(condition_shift)
          condition_code    = condition.to_ruby(condition_context)

          "#{then_code} unless #{condition_code}"
        end

        def to_ruby_multi_line(context)
          combine do |parts|
            parts << "unless #{condition.to_ruby(context.shifted(7))}"
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
            parts << "case #{expression.to_ruby(context.shifted(5))}"
            whens.each do |whem|
              parts << indented(whem, context)
            end
            parts << indented(self.else, context) if self.else
            parts << "end"
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class When < Node
        def to_ruby(context)
          combine do |parts|
            parts << "when #{list(values, ", ", context.shifted(5))}"
            parts << indented(body, context)
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class Else < Node
        def to_ruby(context)
          combine do |parts|
            parts << "else"
            parts << indented(body, context)
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class While < Node
        def to_ruby(context)
          if !body.is_a?(Begin)
            combine do |parts|
              parts << "while #{condition.to_ruby(context.shifted(6))}"
              parts << indented(body, context)
              parts << "end"
            end
          else
            "#{body.to_ruby(context)} while #{condition.to_ruby(context)}"
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class Until < Node
        def to_ruby(context)
          if !body.is_a?(Begin)
            combine do |parts|
              parts << "until #{condition.to_ruby(context.shifted(6))}"
              parts << indented(body, context)
              parts << "end"
            end
          else
            "#{body.to_ruby(context)} until #{condition.to_ruby(context)}"
          end
        end

        def single_line_width
          Float::INFINITY   # always multiline
        end
      end

      class Break < Node
        def to_ruby(context)
          "break"
        end

        def single_line_width
          5
        end
      end

      class Next < Node
        def to_ruby(context)
          "next" + (value ? " #{value.to_ruby(context.shifted(5))}" : "")
        end

        def single_line_width
          value ? 5 + value.single_line_width : 4
        end
      end

      class Return < Node
        def to_ruby(context)
          "return" + (value ? " #{value.to_ruby(context.shifted(7))}" : "")
        end

        def single_line_width
          value ? 7 + value.single_line_width : 6
        end
      end

      # ===== Expressions =====

      class Expressions < Node
        def to_ruby(context)
          if fits_current_line?(context)
            to_ruby_single_line(context)
          else
            to_ruby_multi_line(context)
          end
        end

        def single_line_width
          1 + list_single_line_width(expressions, 2) + 1
        end

        private

        def to_ruby_single_line(context)
          "(#{list(expressions, "; ", context.shifted(1))})"
        end

        def to_ruby_multi_line(context)
          if !expressions.empty?
            wrapped_line_list(expressions, "(", ";", ")", context)
          else
            "()"
          end
        end
      end

      class Assignment < Node
        def to_ruby(context)
          lhs_code = lhs.to_ruby(context)

          # YCP always makes a copy when assigning.
          if rhs.is_a?(Variable)
            rhs_shift   = lhs_code.size + 13
            rhs_context = context.shifted(rhs_shift)
            rhs_code    = "deep_copy(#{rhs.to_ruby(rhs_context)})"
          else
            rhs_shift   = lhs_code.size + 3
            rhs_context = context.shifted(rhs_shift)
            rhs_code    = rhs.to_ruby(rhs_context)
          end

          "#{lhs_code} = #{rhs_code}"
        end

        def single_line_width
          lhs_width = lhs.single_line_width
          rhs_width = if rhs.is_a?(Variable)
            10 + rhs.single_line_width + 1
          else
            rhs.single_line_width
          end

          lhs_width + 3 + rhs_width
        end
      end

      class UnaryOperator < Node
        def to_ruby(context)
          "#{op}#{expression.to_ruby_enclosed(context.shifted(op.size))}"
        end

        def single_line_width
          op.size + expression.single_line_width_enclosed
        end

        protected

        def enclose?
          false
        end
      end

      class BinaryOperator < Node
        def to_ruby(context)
          lhs_code = lhs.to_ruby_enclosed(context)

          rhs_shift   = lhs_code.size + 1 + op.size + 1
          rhs_context = context.shifted(rhs_shift)
          rhs_code    = rhs.to_ruby_enclosed(rhs_context)

          "#{lhs_code} #{op} #{rhs_code}"
        end

        def single_line_width
          lhs_width = lhs.single_line_width_enclosed
          rhs_width = rhs.single_line_width_enclosed

          lhs_width + 1 + op.size + 1 + rhs_width
        end
      end

      class TernaryOperator < Node
        def to_ruby(context)
          condition_code = condition.to_ruby_enclosed(context)

          then_shift   = condition_code.size + 3
          then_context = context.shifted(then_shift)
          then_code    = self.then.to_ruby_enclosed(then_context)

          else_shift   = then_shift + then_code.size + 3
          else_context = context.shifted(else_shift)
          else_code    = self.else.to_ruby_enclosed(else_context)

          "#{condition_code} ? #{then_code} : #{else_code}"
        end

        def single_line_width
          condition_width = condition.single_line_width_enclosed
          then_width      = self.then.single_line_width_enclosed
          else_width      = self.else.single_line_width_enclosed

          condition_width + 3 + then_width + 3 + else_width
        end
      end

      class MethodCall < Node
        def to_ruby(context)
          # The algorithm for deciding whether the call should be split into
          # multile lines is based on seeing if the arguments fit into the
          # current line. That means we ignore the block part. This could lead
          # to some cases where a block starts beyond the right margin (when the
          # arguments fit, but just barely). I decided to ignore these cases, as
          # their impact on readability is minimal and handling them would
          # complicate already complex code.

          receiver_code = receiver ? "#{receiver.to_ruby(context)}." : ""

          args_shift   = receiver_code.size + name.size
          args_context = context.shifted(args_shift)
          args_code    = emit_args(context, args_context)

          if Code.multi_line?(args_code)
            block_context = context.shifted(1)
          else
            block_shift   = args_shift + args_code.size
            block_context = context.shifted(block_shift)
          end
          block_code    = block ? " #{block.to_ruby(block_context)}" : ""

          "#{receiver_code}#{name}#{args_code}#{block_code}"
        end

        def single_line_width
          receiver_width = receiver ? receiver.single_line_width + 1 : 0
          args_width     = args_single_line_width

          receiver_width + name.size + args_width
        end

        protected

        def enclose?
          !parens
        end

        private

        def emit_args(context, args_context)
          if fits_current_line?(context) || !parens
            emit_args_single_line(args_context)
          else
            emit_args_multi_line(args_context)
          end
        end

        def emit_args_single_line(context)
          if !args.empty?
            if parens
              "(#{list(args, ", ", context)})"
            else
              " #{list(args, ", ", context)}"
            end
          else
            !receiver && name =~ /^[A-Z]/ && args.empty? ? "()" : ""
          end
        end

        def emit_args_multi_line(context)
          wrapped_line_list(args, "(", ",", ")", context)
        end

        def args_single_line_width
          if !args.empty?
            if parens
              1 + list_single_line_width(args, 2) + 1
            else
              1 + list_single_line_width(args, 2)
            end
          else
            !receiver && name =~ /^[A-Z]/ && args.empty? ? 2 : 0
          end
        end
      end

      class Block < Node
        def to_ruby(context)
          if fits_current_line?(context)
            to_ruby_single_line(context)
          else
            to_ruby_multi_line(context)
          end
        end

        def single_line_width
          args_width       = list_single_line_width(args, 2)
          statements_width = statements.single_line_width

          if !args.empty?
            3 + args_width + 2 + statements_width + 2
          else
            2 + statements_width + 2
          end
        end

        private

        def to_ruby_single_line(context)
          args_code = if !args.empty?
            " |#{list(args, ", ", context.shifted(3))}|"
          else
            ""
          end

          statements_shift   = 1 + args_code.size + 1
          statements_context = context.shifted(statements_shift)
          statements_code    = statements.to_ruby(statements_context)

          "{#{args_code} #{statements_code} }"
        end

        def to_ruby_multi_line(context)
          args_code = if !args.empty?
            " |#{list(args, ", ", context.shifted(3))}|"
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

        def single_line_width
          (receiver ? receiver.single_line_width + 2 : 0) + name.size
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

        def single_line_width
          name.size
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

        def single_line_width
          4
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

        def single_line_width
          value.inspect.size
        end

        protected

        def enclose?
          false
        end
      end

      class Array < Node
        def to_ruby(context)
          if fits_current_line?(context)
            to_ruby_single_line(context)
          else
            to_ruby_multi_line(context)
          end
        end

        def single_line_width
          2 + list_single_line_width(elements, 2)
        end

        protected

        def enclose?
          false
        end

        private

        def to_ruby_single_line(context)
          "[#{list(elements, ", ", context.shifted(1))}]"
        end

        def to_ruby_multi_line(context)
          if !elements.empty?
            wrapped_line_list(elements, "[", ",", "]", context)
          else
            "[]"
          end
        end
      end

      class Hash < Node
        def to_ruby(context)
          if fits_current_line?(context)
            to_ruby_single_line(context)
          else
            to_ruby_multi_line(context)
          end
        end

        def single_line_width
          if !entries.empty?
            4 + list_single_line_width(entries, 2)
          else
            2
          end
        end

        protected

        def enclose?
          false
        end

        private

        def to_ruby_single_line(context)
          if !entries.empty?
            "{ #{list(entries, ", ", context.shifted(2))} }"
          else
            "{}"
          end
        end

        def to_ruby_multi_line(context)
          if !entries.empty?
            max_key_width = entries.map do |entry|
              entry.key_width(context.indented(INDENT_STEP))
            end.max

            entry_context = context.dup
            entry_context.max_key_width = max_key_width

            wrapped_line_list(entries, "{", ",", "}", entry_context)
          else
            "{}"
          end
        end
      end

      class HashEntry < Node
        def to_ruby(context)
          max_key_width = context.max_key_width

          # We don't want to pass context.max_key_width to the key or value.
          # There can be a hash there for which it could cause problems.
          context = context.dup
          context.max_key_width = nil

          key_code = key.to_ruby(context)

          spacing_code = if max_key_width
            " " * (max_key_width - key_code.size)
          else
            ""
          end

          value_shift   = key_code.size + spacing_code.size + 4
          value_context = context.shifted(value_shift)
          value_code    = value.to_ruby(value_context)

          "#{key_code}#{spacing_code} => #{value_code}"
        end

        def single_line_width
          key_width   = key.single_line_width_enclosed
          value_width = value.single_line_width_enclosed

          key_width + 4 + value_width
        end

        def key_width(context)
          key.to_ruby(context).size
        end

        protected

        def enclose?
          false
        end
      end
    end
  end
end
