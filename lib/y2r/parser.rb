require "cheetah"
require "nokogiri"
require "tempfile"

module Y2R
  class Parser
    class SyntaxError < StandardError
    end

    def parse(input, options = {})
      xml_to_ast(ycp_to_xml(input, options), options)
    end

    private

    def ycp_to_xml(ycp, options)
      module_paths  = options[:module_paths]  || []
      include_paths = options[:include_paths] || []

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
            cmd = [
              options[:ycpc] || "ycpc",
              "--no-std-includes",
              "--no-std-modules",
              "-c",
              "-x",
              "-o", xml_file.path
            ]
            module_paths.each do |module_path|
              cmd << '--module-path' << module_path
            end
            include_paths.each do |include_path|
              cmd << '--include-path' << include_path
            end
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

    def xml_to_ast(xml, options)
      ast = element_to_node(Nokogiri::XML(xml).root)
      ast.filename = options[:filename] || "default.ycp"
      ast
    end

    def element_to_node(element, context = nil)
      case element.name
        when "arg", "cond", "do", "else", "expr", "false", "key", "lhs", "rhs",
             "stmt","then", "true", "until", "value", "ycp"
          element_to_node(element.elements[0], context)

        when "assign"
          AST::YCP::Assign.new(
            :name  => element["name"],
            :child => element_to_node(element.elements[0], context)
          )

        when "block"
          {
            :def    => AST::YCP::DefBlock,
            :file   => AST::YCP::FileBlock,
            :module => AST::YCP::ModuleBlock,
            :stmt   => AST::YCP::StmtBlock,
            :unspec => AST::YCP::UnspecBlock
          }[element["kind"].to_sym].new(
            :name       => element["name"],
            :symbols    => extract_collection(element, "symbols", context),
            :statements => extract_collection(element, "statements", context)
          )

        when "bracket"
          lhs = element.at_xpath("./lhs")

          AST::YCP::Bracket.new(
            :entry => element_to_node(lhs.at_xpath("./entry"), context),
            :arg   => element_to_node(lhs.at_xpath("./arg"), context),
            :rhs   => element_to_node(element.at_xpath("./rhs"), context)
          )

        when "break"
          AST::YCP::Break.new

        when "builtin"
          symbol_attrs = element.attributes.select { |n, v| n =~ /^sym\d+$/ }
          symbol_values = symbol_attrs.values.map(&:value)
          children = extract_children(element, :builtin)

          if symbol_values.empty?
            args  = children
            block = nil
          else
            args  = children[0..-2]
            block = children.last

            block.args = symbol_values.map do |value|
              value =~ /^((\S+\s+)*)(\S+)/

              AST::YCP::Symbol.new(
                :global   => false,
                :category => :variable,
                :type     => $1,
                :name     => $3
              )
            end
            block.symbols = block.args + block.symbols
          end

          AST::YCP::Builtin.new(
            :name    => element["name"],
            :args    => args,
            :block   => block
          )

        when "call"
          AST::YCP::Call.new(
            :ns       => element["ns"],
            :name     => element["name"],
            :category => element["category"],
            :args     => extract_collection(element, "args", context)
          )

        when "case"
          AST::YCP::Case.new(
            :value => element_to_node(element.at_xpath("./value"), context),
            :body  => build_body(extract_collection(element, "body", context))
          )

        when "compare"
          AST::YCP::Compare.new(
            :op  => element["op"],
            :lhs => element_to_node(element.at_xpath("./lhs"), context),
            :rhs => element_to_node(element.at_xpath("./rhs"), context)
          )

        when "const"
          AST::YCP::Const.new(
            :type  => element["type"].to_sym,
            :value => element["value"]
          )

        when "continue"
          AST::YCP::Continue.new

        when "default"
          AST::YCP::Default.new(
            :body => build_body(extract_children(element, context))
          )

        when "element"
          if context != :map
            element_to_node(element.elements[0], context)
          else
            AST::YCP::MapElement.new(
              :key   => element_to_node(element.at_xpath("./key"), context),
              :value => element_to_node(element.at_xpath("./value"), context)
            )
          end

        when "entry"
          AST::YCP::Entry.new(
            :ns   => element["ns"],
            :name => element["name"]
          )

        when "filename"
          AST::YCP::Filename.new

        when "fun_def"
          args = if element.at_xpath("./declaration")
            extract_collection(
              element.at_xpath("./declaration/block"),
              "symbols",
              context
            )
          else
            []
          end
          block = element_to_node(element.at_xpath("./block"), context)

          # This will make the code consider arguments as local variables.
          # Which is exactly what we want e.g. for alias detection.
          block.symbols = args + block.symbols

          AST::YCP::FunDef.new(
            :name  => element["name"],
            :args  => args,
            :block => block,
          )

        when "if"
          AST::YCP::If.new(
            :cond => element_to_node(element.elements[0], context),
            :then => if element.elements[1]
              element_to_node(element.elements[1], context)
            else
              nil
            end,
            :else => if element.elements[2]
              element_to_node(element.elements[2], context)
            else
              nil
            end
          )

        when "import"
          AST::YCP::Import.new(:name => element["name"])

        when "include"
          AST::YCP::Include.new

        when "list"
          AST::YCP::List.new(:children => extract_children(element, :list))

        when "locale"
          AST::YCP::Locale.new(:text => element["text"])

        when "map"
          AST::YCP::Map.new(:children => extract_children(element, :map))

        when "repeat"
          # For some reason, blocks in |repeat| statements are of kind "unspec"
          # but they really should be "stmt". Thus we need to construct the
          # |StmtBlock| instance ourself.

          block_element = element.at_xpath("./do/block")

          AST::YCP::Repeat.new(
            :do    => if block_element
              AST::YCP::StmtBlock.new(
                :name       => nil,
                :symbols    => extract_collection(block_element, "symbols", context),
                :statements => extract_collection(block_element, "statements", context)
              )
            else
              nil
            end,
            :until => element_to_node(element.at_xpath("./until"), context)
          )

        when "return"
          AST::YCP::Return.new(
            :child => if element.elements[0]
              element_to_node(element.elements[0], context)
            else
              nil
            end
          )

        when "switch"
          case_elements = element.elements.select { |e| e.name == "case" }

          AST::YCP::Switch.new(
            :cond    => element_to_node(element.at_xpath("./cond"), context),
            :cases   => case_elements.map { |e| element_to_node(e, context) },
            :default => if element.at_xpath("./default")
              element_to_node(element.at_xpath("./default"), context)
            else
              nil
            end
          )

        when "symbol"
          category = element["category"].to_sym

          AST::YCP::Symbol.new(
            :global   => element["global"] == "1",
            :category => category,
            :type     => element["type"],
            # We don't save names for files mainly because of the specs. They
            # use temporary files with unpredictable names and node equality
            # tests would fail because of that.
            :name     => if category != :filename
              element["name"]
            else
              nil
            end
          )

        when "textdomain"
          AST::YCP::Textdomain.new(:name => element["name"])

        when "typedef"
          AST::YCP::Typedef.new

        when "variable"
          AST::YCP::Variable.new(
            :name     => element["name"],
            :category => element["category"],
            :type     => element["type"]
          )

        when "while"
          AST::YCP::While.new(
            :cond => element_to_node(element.at_xpath("./cond"), context),
            :do   => if element.at_xpath("./do")
              element_to_node(element.at_xpath("./do"), context)
            else
              nil
            end
          )

        when "ycpcode"
          AST::YCP::YCPCode.new(
            :args    => [],
            :symbols => [],
            :child   => element_to_node(element.elements[0], context)
          )

        when "yebinary"
          AST::YCP::YEBinary.new(
            :name => element["name"],
            :lhs  => element_to_node(element.elements[0], context),
            :rhs  => element_to_node(element.elements[1], context)
          )

        when "yebracket"
          AST::YCP::YEBracket.new(
            :value   => element_to_node(element.elements[0], context),
            :index   => element_to_node(element.elements[1], context),
            :default => element_to_node(element.elements[2], context)
          )

        when "yeis"
          AST::YCP::YEIs.new(
            :type  => element["type"],
            :child => element_to_node(element.elements[0], context)
          )

        when "yepropagate"
          AST::YCP::YEPropagate.new(
            :from  => element["from"],
            :to    => element["to"],
            :child => element_to_node(element.elements[0], context)
          )

        when "yereference"
          AST::YCP::YEReference.new(
            :child => element_to_node(element.elements[0], context)
          )

        when "yereturn"
          AST::YCP::YEReturn.new(
            :args    => [],
            :symbols => [],
            :child   => element_to_node(element.elements[0], context)
          )

        when "yeterm"
          AST::YCP::YETerm.new(
            :name     => element["name"],
            :children => extract_children(element, :yeterm)
          )

        when "yetriple"
          AST::YCP::YETriple.new(
            :cond  => element_to_node(element.at_xpath("./cond"), context),
            :true  => element_to_node(element.at_xpath("./true"), context),
            :false => element_to_node(element.at_xpath("./false"), context)
          )

        when "yeunary"
          AST::YCP::YEUnary.new(
            :name  => element["name"],
            :child => element_to_node(element.elements[0], context)
          )

        else
          raise "Invalid element: <#{element.name}>."
      end
    end

    def extract_children(element, context)
      element.elements.map { |e| element_to_node(e, context) }
    end

    def extract_collection(element, name, context)
      child = element.at_xpath("./#{name}")
      child ? extract_children(child, context) : []
    end

    def build_body(statements)
      if statements.size == 1 && statements.first.is_a?(AST::YCP::StmtBlock)
        body = statements.first
      else
        body = AST::YCP::StmtBlock.new(
          :name       => nil,
          :symbols    => [],
          :statements => statements
        )
      end
    end
  end
end
