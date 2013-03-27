require "ostruct"

module Y2R
  module AST
    module YCP
      class Node < OpenStruct
        # Taken from Ruby's parse.y (for 1.9.3).
        RUBY_KEYWORDS = [
          "BEGIN",
          "END",
          "__ENCODING__",
          "__FILE__",
          "__LINE__",
          "alias",
          "and",
          "begin",
          "break",
          "case",
          "class",
          "def",
          "defined",
          "do",
          "else",
          "elsif",
          "end",
          "ensure",
          "false",
          "for",
          "if",
          "in",
          "module",
          "next",
          "nil",
          "not",
          "or",
          "redo",
          "rescue",
          "retry",
          "return",
          "self",
          "super",
          "then",
          "true",
          "undef",
          "unless",
          "until",
          "when",
          "while",
          "yield"
        ]

        def indent(n, s)
          s.gsub(/^(?=.)/, " " * n)
        end

        def combine
          parts = []
          yield parts
          parts.join("\n")
        end

        def inside_block(context)
          inner_context = context.dup
          inner_context.blocks = inner_context.blocks + [self]

          yield inner_context
        end

        def strip_const(type)
          type.sub(/^const /, "")
        end

        def qualified_name(ns, name)
          (ns ? "#{ns}::" : "") + name
        end

        # Escapes valid YCP variable names that are not valid Ruby local variable
        # names.
        def escape_ruby_local_var_name(name)
          name.sub(/^(#{RUBY_KEYWORDS.join("|")}|[A-Z_].*)$/) { |s| "_#{s}" }
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
            $1 == context.module_name ? "@#$2" : "#$1.#$2"
          else
            is_local = context.local_variables.include?(name)
            variables = if is_local
              context.local_variables
            else
              context.global_variables
            end

            # If there already is a variable with given name (coming from some
            # parent scope), suffix the variable name with "2". If there are two
            # such variables, suffix the name with "3". And so on.
            #
            # The loop is needed because we need to do the same check and maybe
            # additional round(s) of suffixing also for suffixed variable names to
            # prevent conflicts.
            suffixed_name = name
            begin
              count = variables.select { |v| v == suffixed_name }.size
              suffixed_name = suffixed_name + count.to_s if count > 1
            end while count > 1

            if is_local
              escape_ruby_local_var_name(suffixed_name)
            else
              "@#{suffixed_name}"
            end
          end
        end

        def ruby_method_name(name)
          name.sub("::", ".")
        end

        def ruby_list(items, context)
          items.map { |i| i.to_ruby(context) }.join(", ")
        end

        def ruby_method_args(args, context)
          !args.empty? ? "(#{ruby_list(args, context)})" : ""
        end

        def ruby_block_args(args, context)
          arg_names = args.map { |a| ruby_var_name(a.name, context) }

          !args.empty? ? " |#{arg_names.join(", ")}|" : ""
        end

        def ruby_stmts(stmts, context)
          stmts.map { |s| s.to_ruby(context) }.join("\n")
        end
      end

      class Block < Node
        def variables
          symbols.select { |s| s.category == :variable }.map(&:name)
        end
      end

      class Context
        attr_accessor :blocks

        def initialize(attrs = {})
          @blocks = attrs[:blocks] || []
        end

        def in?(klass)
          @blocks.find { |b| b.is_a?(klass) } ? true : false
        end

        def innermost(*klasses)
          @blocks.reverse.find { |b| klasses.any? { |k| b.is_a?(k) } }
        end

        def module_name
          toplevel_block = @blocks.first
          toplevel_block.is_a?(ModuleBlock) ? toplevel_block.name : nil
        end

        def variables_in_scope
          index = @blocks.rindex { |b| b.is_a?(DefBlock) }
          scope_blocks = index ? @blocks[index..-1] : @blocks
          scope_blocks.reverse.map(&:variables).flatten
        end

        def local_variables
          index = @blocks.index { |b| b.is_a?(DefBlock) || b.is_a?(UnspecBlock) || b.is_a?(YCPCode) || b.is_a?(YEReturn) } || @blocks.length
          @blocks[index..-1].map(&:variables).flatten
        end

        def global_variables
          index = @blocks.index { |b| b.is_a?(DefBlock) || b.is_a?(UnspecBlock) || b.is_a?(YCPCode) || b.is_a?(YEReturn) } || @blocks.length
          @blocks[0..index - 1].map(&:variables).flatten
        end
      end

      # Sorted alphabetically.

      class Assign < Node
        def to_ruby(context = Context.new)
          "#{ruby_var_name(name, context)} = #{child.to_ruby(context)}"
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
            While       => "break",
            Repeat      => "break",
            UnspecBlock => "raise Break"
          }[context.innermost(While, Repeat, UnspecBlock).class]
        end
      end

      class Builtin < Node
        def to_ruby(context = Context.new)
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
            " #{block.to_ruby_block(context)}"
          else
            ""
          end

          "#{module_name}.#{method_name}#{ruby_method_args(args, context)}#{block_code}"
        end
      end

      class Call < Node
        def to_ruby(context = Context.new)

          method_name = case category 
            when "variable" # function reference stored in variable
              ruby_var_name(name, context) + ".call"
            when "function"
              ruby_method_name(qualified_name(ns, name))
            else
              raise "Unknown call category: #{category.inspect}."
          end

          if !ns && method_name =~ /^[A-Z]/ && args.empty?
            "#{method_name}()"
          else
            "#{method_name}#{ruby_method_args(args, context)}"
          end
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
              raise "Unknown const type: #{type.inspect}."
          end
        end
      end

      class Continue < Node
        def to_ruby(context = Context.new)
          "next"
        end
      end

      class DefBlock < Block
        def to_ruby(context = Context.new)
          inside_block context do |inner_context|
            ruby_stmts(statements, inner_context)
          end
        end
      end

      class Entry < Node
        def to_ruby(context = Context.new)
          ruby_var_name(qualified_name(ns, name), context)
        end
      end

      class FileBlock < Block
        def to_ruby(context = Context.new)
          client_name = File.basename(filename).sub(/\.[^.]*$/, "")
          class_name = client_name.
            gsub(/^./)    { |s| s.upcase    }.
            gsub(/[_-]./) { |s| s[1].upcase } + "Client"

          textdomains = statements.select { |s| s.is_a?(Textdomain) }
          fundefs = statements.select { |s| s.is_a?(FunDef) }
          other_statements = statements - textdomains - fundefs

          combine do |parts|
            parts << "module YCP"
            parts << "  module Clients"
            parts << "    class #{class_name}"

            inside_block context do |inner_context|
              unless textdomains.empty?
                parts << indent(6, ruby_stmts(textdomains, inner_context))
              end

              unless other_statements.empty?
                parts << "      def main"
                parts << indent(8, ruby_stmts(other_statements, inner_context))
                parts << "      end"
              end

              unless fundefs.empty?
                parts << ""
                parts << indent(6, ruby_stmts(fundefs, inner_context))
              end
            end

            parts << "    end"
            parts << "  end"
            parts << "end"
            parts << ""
            parts << "YCP::Clients::#{class_name}.new.main"
          end
        end
      end

      class Filename < Node
        def to_ruby(context = Context.new)
          ""
        end
      end

      class FunDef < Node
        def to_ruby(context = Context.new)
          if context.in?(DefBlock)
            raise NotImplementedError,
                 "Nested function enountered: #{name.inspect}. Nested functions are not supported."
          end

          combine do |parts|
            parts << "def #{name}#{ruby_method_args(args, context)}"

            args.each do |arg|
              parts << indent(2, arg.to_ruby_copy_call) if arg.needs_copy?
            end

            parts << indent(2, block.to_ruby(context))
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
            parts << "if #{cond.to_ruby(context)}"
            if self.then
              parts << indent(2, self.then.to_ruby(context))
            end
            if self.else
              parts << "else"
              parts << indent(2, self.else.to_ruby(context))
            end
            parts << "end"
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

      class Include < Node
        def to_ruby(context = Context.new)
          ""
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

      class ModuleBlock < Block
        def to_ruby(context = Context.new)
          real_name = name.sub(/\.ycp$/, "")
          textdomains = statements.select { |s| s.is_a?(Textdomain) }
          fundefs = statements.select { |s| s.is_a?(FunDef) }
          other_statements = statements - textdomains - fundefs

          combine do |parts|
            parts << "require \"ycp\""
            parts << ""
            parts << "module YCP"
            parts << "  class #{real_name}Class"
            parts << "    extend Exportable"

            inside_block context do |inner_context|
              unless textdomains.empty?
                parts << indent(4, ruby_stmts(textdomains, inner_context))
              end

              unless other_statements.empty?
                parts << ""
                parts << "    def initialize"
                parts << indent(6, ruby_stmts(other_statements, inner_context))
                parts << "    end"
              end

              unless fundefs.empty?
                parts << ""
                parts << indent(4, ruby_stmts(fundefs, inner_context))
              end
            end

            symbols.each do |symbol|
              if symbol.published?
                parts << indent(4, symbol.to_ruby_publish_call)
              end
            end

            parts << "  end"
            parts << ""
            parts << "  #{real_name} = #{real_name}Class.new"
            parts << "end"
          end
        end
      end

      class Repeat < Node
        def variables
          []
        end

        def to_ruby(context = Context.new)
          combine do |parts|
            parts << "begin"
            if self.do
              inside_block context do |inner_context|
                parts << indent(2, self.do.to_ruby(inner_context))
              end
            end
            parts << "end until #{self.until.to_ruby(context)}"
          end
        end
      end

      class Return < Node
        def to_ruby(context = Context.new)
          stmt = {
            DefBlock    => "return",
            UnspecBlock => "next"
          }[context.innermost(DefBlock, UnspecBlock).class]

          if child
            "#{stmt} #{child.to_ruby(context)}"
          else
            stmt
          end
        end
      end

      class StmtBlock < Block
        def to_ruby(context = Context.new)
          inside_block context do |inner_context|
            ruby_stmts(statements, inner_context)
          end
        end
      end

      class Symbol < Node
        def needs_copy?
          strip_const(type) !~ /^(boolean|integer|symbol)$|&$/
        end

        def published?
          global && (category == :variable || category == :function)
        end

        def to_ruby(context = Context.new)
          ruby_name
        end

        def to_ruby_copy_call
          "#{ruby_name} = YCP.copy(#{ruby_name})"
        end

        def to_ruby_publish_call
          "publish :#{category} => :#{name}, :type => \"#{type}\""
        end

        private

        def ruby_name
          escape_ruby_local_var_name(name)
        end
      end

      class Textdomain < Node
        def to_ruby(context = Context.new)
          combine do |parts|
            parts << "include I18n"
            parts << "textdomain #{name.inspect}"
            parts << ""
          end
        end
      end

      class Typedef < Node
        def to_ruby(context = Context.new)
          # Typedefs can be completely ignored because ycpc expands defined types
          # in the XML, so we never actually encounter them.
          ""
        end
      end

      class UnspecBlock < Block
        def to_ruby(context = Context.new)
          combine do |parts|
            inside_block context do |inner_context|
              parts << "lambda {"
              parts << indent(2, ruby_stmts(statements, inner_context))
              parts << "}"
            end
          end
        end

        def to_ruby_block(context = Context.new)
          combine do |parts|
            inside_block context do |inner_context|
              parts << "{#{ruby_block_args(args, inner_context)}"
              parts << indent(2, ruby_stmts(statements, inner_context))
              parts << "}"
            end
          end
        end
      end

      class Variable < Node
        def to_ruby(context = Context.new)
          case category
            when "variable", "reference"
              ruby_var_name(name, context)
            when "function"
              parts = name.split("::")
              ns = parts.size > 1 ? parts.first : nil
              variable_name = parts.last

              ns_prefix = ns ? ns + "." : ""
              "Reference.new(#{ns_prefix}method(:#{variable_name}), \"#{type}\")"
            else
              raise "Unknown variable category: #{category.inspect}."
          end
        end
      end

      class While < Node
        def variables
          []
        end

        def to_ruby(context = Context.new)
          combine do |parts|
            parts << "while #{cond.to_ruby(context)}"
            if self.do
              inside_block context do |inner_context|
                parts << indent(2, self.do.to_ruby(inner_context))
              end
            end
            parts << "end"
          end
        end
      end

      class YCPCode < Node
        def variables
          symbols.select { |s| s.category == :variable }.map(&:name)
        end

        def to_ruby(context = Context.new)
          "lambda { #{child.to_ruby(context)} }"
        end

        def to_ruby_block(context = Context.new)
          inside_block context do |inner_context|
            "{#{ruby_block_args(args, inner_context)} #{child.to_ruby(inner_context)} }"
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

      class YEIs < Node
        def to_ruby(context = Context.new)
          "Ops.is(#{child.to_ruby(context)}, \"#{type}\")"
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

      class YEReference < Node
        def to_ruby(context = Context.new)
          child.to_ruby(context)
        end
      end

      class YEReturn < Node
        def variables
          symbols.select { |s| s.category == :variable }.map(&:name)
        end

        def to_ruby(context = Context.new)
          "lambda { #{child.to_ruby(context)} }"
        end

        def to_ruby_block(context = Context.new)
          inside_block context do |inner_context|
            "{#{ruby_block_args(args, inner_context)} #{child.to_ruby(inner_context)} }"
          end
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
end
