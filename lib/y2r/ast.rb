require "ostruct"

module Y2R
  module AST
    class Node < OpenStruct
      def indent(s)
        s.gsub(/^(?=.)/, "  ")
      end

      def combine
        parts = []
        yield parts
        parts.join("\n")
      end

      def strip_const(type)
        type.sub(/^const /, "")
      end

      # Escapes valid YCP variable names that are not valid Ruby local variable
      # names.
      def escape_ruby_local_var_name(name)
        name.gsub(/^[A-Z_]/) { |ch| "_#{ch}" }
      end

      # Translates a variable name from ycpc's XML into its Ruby counterpart.
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

      def ruby_list(items, context)
        items.map { |i| i.to_ruby(context) }.join(", ")
      end

      def ruby_args(args, context)
        !args.empty? ? "(#{ruby_list(args, context)})" : ""
      end

      def ruby_stmts(stmts, context)
        stmts.map { |s| s.to_ruby(context) }.join("\n")
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
            ruby_stmts(statements, statements_context)
          when :module
            statements_context.module_name = name

            assigns = statements.select { |s| s.is_a?(Assign) }
            fundefs = statements.select { |s| s.is_a?(FunDef) }
            other_statements = statements - assigns - fundefs

            combine do |parts|
              parts << "require \"ycp\""
              parts << ""
              parts << "module YCP"
              parts << "  class #{name}Class"
              parts << "    extend Exportable"

              unless other_statements.empty?
                parts << ""
                parts << indent(indent(ruby_stmts(other_statements, statements_context)))
              end

              unless assigns.empty?
                parts << ""
                parts << "    def initialize"
                parts << indent(indent(indent(ruby_stmts(assigns, statements_context))))
                parts << "    end"
              end

              unless fundefs.empty?
                parts << ""
                parts << indent(indent(ruby_stmts(fundefs, statements_context)))
              end

              symbols.each do |symbol|
                if symbol.published?
                  parts << indent(indent(symbol.to_ruby_publish_call))
                end
              end

              parts << "  end"
              parts << ""
              parts << "  #{name} = #{name}Class.new"
              parts << "end"
            end
          when :unspec
            combine do |parts|
              parts << "lambda {"
              parts << indent(ruby_stmts(statements, statements_context))
              parts << "}"
            end
          else
            raise "Unknown block kind: #{kind}."
        end
      end

      def to_ruby_block(args, context = Context.new)
        statements_context = context.dup
        statements_context.blocks = statements_context.blocks + [kind]

        combine do |parts|
          parts << "{ |#{args.join(", ")}|"
          parts << indent(ruby_stmts(statements, statements_context))
          parts << "}"
        end
      end
    end

    class Bracket < Node
      def to_ruby(context = Context.new)
        entry_code = entry.to_ruby(context)
        arg_code   = arg.to_ruby(context)
        rhs_code   = rhs.to_ruby(context)

        "Ops.assign(#{entry_code}, #{arg_code}, #{rhs_code})"
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

        module_name = case name
          when /^SCR::/
            "SCR"
          when /^WFM::/
            "WFM"
          when /^float::/
            "Builtins::Float"
          when /^list::/
            "Builtins::List"
          else
            "Builtins"
        end

        method_name = name.split("::").last

        block_code = if block
          " #{block.to_ruby_block(symbols.map { |s| s.split(" ").last }, context)}"
        else
          ""
        end

        "#{module_name}.#{method_name}#{ruby_args(args, context)}#{block_code}"
      end
    end

    class Call < Node
      def to_ruby(context = Context.new)
        "#{ns}.#{name}#{ruby_args(args, context)}"
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
        lhs_code = lhs.to_ruby(context)
        rhs_code = rhs.to_ruby(context)

        "Ops.#{OPS_TO_METHODS[op]}(#{lhs_code}, #{rhs_code})"
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

        combine do |parts|
          parts << "def #{name}#{ruby_args(args, context)}"

          args.each do |arg|
            parts << indent(arg.to_ruby_copy_call) if arg.needs_copy?
          end

          parts << indent(block.to_ruby(context))
          parts << ""
          parts << "  nil"
          parts << "end"
          parts << ""
        end
      end
    end

    class If < Node
      def to_ruby(context = Context.new)
        combine do |parts|
          if self.else
            parts << "if #{cond.to_ruby(context)}"
            parts << indent(self.then.to_ruby(context))
            parts << "else"
            parts << indent(self.else.to_ruby(context))
            parts << "end"
          else
            parts << "if #{cond.to_ruby(context)}"
            parts << indent(self.then.to_ruby(context))
            parts << "end"
          end
        end
      end
    end

    class Import < Node
      def to_ruby(context = Context.new)
        # Using any SCR or WFM function results in an auto-import. We ignore
        # these auto-imports becasue neither SCR nor WFM are real modules.
        return "" if name == "SCR" || name == "WFM"

        combine do |parts|
          parts << "YCP.import(#{name.inspect})"
          parts << ""
        end
      end
    end

    class List < Node
      def to_ruby(context = Context.new)
        "[#{ruby_list(children, context)}]"
      end
    end

    class Locale < Node
      def to_ruby(context = Context.new)
        "_(#{text.inspect})"
      end
    end

    class Map < Node
      def to_ruby(context = Context.new)
        !children.empty? ? "{ #{ruby_list(children, context)} }" : "{}"
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
      def needs_copy?
        !["boolean", "integer", "symbol"].include?(strip_const(type))
      end

      def published?
        global && (category == :variable || category == :function)
      end

      def to_ruby(context = Context.new)
        name
      end

      def to_ruby_copy_call
        "#{name} = YCP.copy(#{name})"
      end

      def to_ruby_publish_call
        "publish :#{category} => :#{name}, :type => \"#{type}\""
      end
    end

    class Textdomain < Node
      def to_ruby(context = Context.new)
        combine do |parts|
          parts << "FastGettext.text_domain = #{name.inspect}"
          parts << ""
        end
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

        combine do |parts|
          parts << "while #{cond.to_ruby(context)}"
          parts << indent(self.do.to_ruby(do_context))
          parts << "end"
        end
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
        lhs_code = lhs.to_ruby(context)
        rhs_code = rhs.to_ruby(context)

        "Ops.#{OPS_TO_METHODS[name]}(#{lhs_code}, #{rhs_code})"
      end
    end

    class YEBracket < Node
      def to_ruby(context = Context.new)
        value_code   = value.to_ruby(context)
        index_code   = index.to_ruby(context)
        default_code = default.to_ruby(context)

        "Ops.index(#{value_code}, #{index_code}, #{default_code})"
      end
    end

    class YEPropagate < Node
      def to_ruby(context = Context.new)
        from_no_const = strip_const(from)
        to_no_const   = strip_const(to)

        if from_no_const != to_no_const
          child_code = child.to_ruby(context)
          from_code  = from_no_const.inspect
          to_code    = to_no_const.inspect

          "Convert.convert(#{child_code}, :from => #{from_code}, :to => #{to_code})"
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
          "Term.new(:#{name}, #{ruby_list(children, context)})"
        else
          "Term.new(:#{name})"
        end
      end
    end

    class YETriple < Node
      def to_ruby(context = Context.new)
        cond_code  = cond.to_ruby(context)
        true_code  = self.true.to_ruby(context)
        false_code = self.false.to_ruby(context)

        "#{cond_code} ? #{true_code} : #{false_code}"
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
