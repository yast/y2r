require "cheetah"
require "rexml/document"
require "tempfile"

module Y2R
  class Parser
    class SyntaxError < StandardError
    end

    def parse(input, options = {})
      xml_to_ast(ycp_to_xml(input, options))
    end

    private

    def ycp_to_xml(ycp, options)
      ycp_file = Tempfile.new("y2r")
      begin
        begin
          ycp_file.write(ycp)
        ensure
          ycp_file.close
        end

        xml_file = Tempfile.new("y2r")
        xml_file.close
        begin
          begin
            cmd = options[:ycpc] || "ycpc", "-c", "-x", "-o", xml_file.path
            cmd << '--module-path' << options[:module_path] if options[:module_path]
            cmd << '--include-path' << options[:include_path] if options[:include_path]
            cmd << ycp_file.path

            Cheetah.run(cmd)
          rescue Cheetah::ExecutionFailed => e
            raise SyntaxError.new(e.stderr)
          end

          File.read(xml_file.path)
        ensure
          xml_file.unlink
        end
      ensure
        ycp_file.unlink
      end
    end

    def xml_to_ast(xml)
      element_to_node(REXML::Document.new(xml).root)
    end

    def element_to_node(element, context = nil)
      case element.name
        when "arg", "cond", "do", "else", "expr", "false", "key", "lhs", "rhs",
             "stmt","then", "true", "value", "ycp"
          element_to_node(element.elements[1], context)
        when "assign"
          AST::Assign.new(
            :name  => element.attributes["name"],
            :child => element_to_node(element.elements[1], context)
          )
        when "block"
          AST::Block.new(
            :kind       => element.attributes["kind"].to_sym,
            :symbols    => extract_collection(element, "symbols", context),
            :statements => extract_collection(element, "statements", context)
          )
        when "bracket"
          lhs = element.elements["lhs"]
          AST::Bracket.new(
            :entry => element_to_node(lhs.elements["entry"], context),
            :arg   => element_to_node(lhs.elements["arg"], context),
            :rhs   => element_to_node(element.elements["rhs"], context)
          )
        when "break"
          AST::Break.new
        when "builtin"
          symbol_attrs = element.attributes.select { |n, v| n =~ /^sym\d+$/ }
          AST::Builtin.new(
            :name     => element.attributes["name"],
            :symbols  => symbol_attrs.values.map(&:value),
            :children => extract_children(element, :builtin)
          )
        when "call"
          AST::Call.new(
            :ns   => element.attributes["ns"],
            :name => element.attributes["name"],
            :args => extract_collection(element, "args", context)
          )
        when "compare"
          AST::Compare.new(
            :op  => element.attributes["op"],
            :lhs => element_to_node(element.elements["lhs"], context),
            :rhs => element_to_node(element.elements["rhs"], context)
          )
        when "const"
          AST::Const.new(
            :type  => element.attributes["type"].to_sym,
            :value => element.attributes["value"]
          )
        when "continue"
          AST::Continue.new
        when "element"
          if context != :map
            element_to_node(element.elements[1], context)
          else
            AST::MapElement.new(
              :key   => element_to_node(element.elements["key"], context),
              :value => element_to_node(element.elements["value"], context)
            )
          end
        when "entry"
          AST::Entry.new(:name => element.attributes["name"])
        when "fun_def"
          AST::FunDef.new(
            :name  => element.attributes["name"],
            :args  => if element.elements["declaration"]
              extract_collection(
                element.elements["declaration"].elements["block"],
                "symbols",
                context
              )
            else
              []
            end,
            :block => element_to_node(element.elements["block"], context),
          )
        when "if"
          AST::If.new(
            :cond => element_to_node(element.elements[1], context),
            :then => element_to_node(element.elements[2], context),
            :else => if element.elements.size > 2
              element_to_node(element.elements[3], context)
            else
              nil
            end
          )
        when "import"
          AST::Import.new(:name => element.attributes["name"])
        when "list"
          AST::List.new(:children => extract_children(element, :list))
        when "locale"
          AST::Locale.new(:text => element.attributes["text"])
        when "map"
          AST::Map.new(:children => extract_children(element, :map))
        when "return"
          AST::Return.new(
            :child => if element.elements[1]
              element_to_node(element.elements[1], context)
            else
              nil
            end
          )
        when "symbol"
          if element.attributes["category"] == "filename"
            AST::Symbol.new
          else
            AST::Symbol.new(:name  => element.attributes["name"])
          end
        when "textdomain"
          AST::Textdomain.new(:name => element.attributes["name"])
        when "variable"
          AST::Variable.new(:name => element.attributes["name"])
        when "while"
          AST::While.new(
            :cond => element_to_node(element.elements["cond"], context),
            :do   => element_to_node(element.elements["do"], context)
          )
        when "yebinary"
          AST::YEBinary.new(
            :name => element.attributes["name"],
            :lhs  => element_to_node(element.elements[1], context),
            :rhs  => element_to_node(element.elements[2], context)
          )
        when "yebracket"
          AST::YEBracket.new(
            :value   => element_to_node(element.elements[1], context),
            :index   => element_to_node(element.elements[2], context),
            :default => element_to_node(element.elements[3], context)
          )
        when "yepropagate"
          AST::YEPropagate.new(
            :from  => element.attributes["from"],
            :to    => element.attributes["to"],
            :child => element_to_node(element.elements[1], context)
          )
        when "yereturn"
          AST::YEReturn.new(
            :child => element_to_node(element.elements[1], context)
          )
        when "yeterm"
          AST::YETerm.new(
            :name     => element.attributes["name"],
            :children => extract_children(element, :yeterm)
          )
        when "yetriple"
          AST::YETriple.new(
            :cond  => element_to_node(element.elements["cond"], context),
            :true  => element_to_node(element.elements["true"], context),
            :false => element_to_node(element.elements["false"], context)
          )
        when "yeunary"
          AST::YEUnary.new(
            :name  => element.attributes["name"],
            :child => element_to_node(element.elements[1], context)
          )
        else
          raise "Invalid element: <#{element.name}>."
      end
    end

    def extract_children(element, context)
      element.elements.map { |e| element_to_node(e, context) }
    end

    def extract_collection(element, name, context)
      child = element.elements[name]
      child ? extract_children(child, context) : []
    end
  end
end
