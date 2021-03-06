# encoding: utf-8

require "cheetah"
require "nokogiri"
require "tempfile"

module Y2R
  class Parser

    # The lists of elements skipped during parsing and comment processing need
    # to differ. Currently there are two reasons:
    #
    #   * When parsing, we want to skip <yconst>, because it's just a useless
    #     wrapper. But when processing comments we don't want to skip it,
    #     because this is the element to which comments are attached to for
    #     various literals.
    #
    #   * When parsing, we don't want to skip <element>, because we need to
    #     handle it specially in case it's inside <map>. But when processing
    #     comments it's just a useless wrapper.

    SKIPPED_ELEMENTS_PARSING = [
      "arg",
      "cond",
      "else",
      "expr",
      "false",
      "key",
      "lhs",
      "rhs",
      "stmt",
      "then",
      "true",
      "until",
      "value",
      "yconst",
      "ycp"
    ]

    SKIPPED_ELEMENTS_COMMENTS = [
      "arg",
      "cond",
      "element",
      "else",
      "expr",
      "false",
      "key",
      "lhs",
      "rhs",
      "stmt",
      "then",
      "true",
      "until",
      "value",
      "ycp"
    ]

    class SyntaxError < StandardError
    end

    def initialize(options = {})
      @options = options
    end

    def parse(input)
      xml = ycp_to_xml(input)

      if !@options[:xml]
        xml_to_ast(xml)
      else
        xml
      end
    end

    private

    def ycp_to_xml(ycp)
      module_paths  = @options[:module_paths]  || []
      include_paths = @options[:include_paths] || []

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
            ENV["Y2PARSECOMMENTS"] = "1"

            cmd = [
              "ycpc",
              "--no-std-modules",
              "--no-std-includes",
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

    def xml_to_ast(xml)
      root = Nokogiri::XML(xml).root

      # Comment processing in ycpc is rough and comments often get attached to
      # wrong nodes. This is a deliberate decision because it is easier to fix
      # comments here than to do the right thing in ycpc.
      fix_comments(root, nil)

      ast = element_to_node(root, nil)
      ast.filename = if @options[:reported_file]
        @options[:reported_file]
      else
        @options[:filename] || "default.ycp"
      end
      ast
    end

    def fix_comments(element, last_element)
      # We don't want to attach any comments to these.
      if SKIPPED_ELEMENTS_COMMENTS.include?(element.name)
        fix_comments(element.elements[0], last_element)
        return
      end

      # In general, ycpc collects comments and they end up as |comment_before|
      # at the next AST node that is created. In reality, parts of the comments
      # may belong to the previous node (passed as |last_element|).
      comment_before = element["comment_before"]
      if last_element && comment_before
        if comment_before =~ /\n/
          after_part, before_part = comment_before.split("\n", 2)
        else
          after_part, before_part = comment_before, ""
        end

        if !after_part.empty?
          if last_element["comment_after"]
            last_element["comment_after"] = after_part + last_element["comment_after"]
          else
            last_element["comment_after"] = after_part
          end
        end

        if !before_part.empty?
          element["comment_before"] = before_part
        else
          element.attributes["comment_before"].remove
        end
      end

      # Recurse into children.
      last_element = element
      element.elements.each do |child|
        fix_comments(child, last_element)
        last_element = child
      end
    end

    def element_to_node(element, context)
      node = case element.name
        when *SKIPPED_ELEMENTS_PARSING
          element_to_node(element.elements[0], context)

        when "assign"
          AST::YCP::Assign.new(
            :ns    => element["ns"],
            :name  => element["name"],
            :child => element_to_node(element.elements[0], context)
          )

        when "block"
          all_statements = extract_collection(element, "statements", context)

          extracted_statements = if toplevel_block?(element) && @options[:extracted_file]
            extract_file_statements(all_statements, @options[:extracted_file])
          else
            all_statements
          end

          statements = if toplevel_block?(element)
            skip_include_statements(extracted_statements)
          else
            extracted_statements
          end

          file_block_class = if @options[:as_include_file]
            AST::YCP::IncludeBlock
          else
            AST::YCP::FileBlock
          end

          module_block_class = if @options[:as_include_file]
            AST::YCP::IncludeBlock
          else
            AST::YCP::ModuleBlock
          end

          {
            :def    => AST::YCP::DefBlock,
            :file   => file_block_class,
            :module => module_block_class,
            :stmt   => AST::YCP::StmtBlock,
            :unspec => AST::YCP::UnspecBlock
          }[element["kind"].to_sym].new(
            :name       => element["name"],
            :symbols    => extract_symbols(element, context),
            :statements => statements
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
                :type     => AST::YCP::Type.new($1),
                :name     => $3
              )
            end
            block.symbols = block.args + block.symbols
          end

          AST::YCP::Builtin.new(
            :ns      => element["ns"],
            :name    => element["name"],
            :args    => args,
            :block   => block
          )

        when "call"
          AST::YCP::Call.new(
            :ns       => element["ns"],
            :name     => element["name"],
            :category => element["category"].to_sym,
            :result   => element["result"] == "unused" ? :unused : :used,
            :args     => extract_collection(element, "args", context),
            :type     => AST::YCP::Type.new(element["type"])
          )

        when "case"
          value_elements = element.elements.select { |e| e.name == "value" }

          AST::YCP::Case.new(
            :values => value_elements.map { |e| element_to_node(e, context) },
            :body   => build_body(extract_collection(element, "body", context))
          )

        when "compare"
          AST::YCP::Compare.new(
            :op  => element["op"],
            :lhs => element_to_node(element.at_xpath("./lhs"), context),
            :rhs => element_to_node(element.at_xpath("./rhs"), context)
          )

        when "const"
          # For some weird reason, some terms (e.g. those placed in lists) are
          # represented as <const type="term" ...>, while others are represented
          # as <yeterm ...>. We unify this mess here so that it doesn't
          # propagate into the AST.
          if element["type"] != "term"
            AST::YCP::Const.new(
              :type  => element["type"].to_sym,
              :value => element["value"]
            )
          else
            AST::YCP::YETerm.new(
              :name     => element["name"],
              :children => extract_collection(element, "list", :yeterm)
            )
          end

        when "continue"
          AST::YCP::Continue.new

        when "default"
          AST::YCP::Default.new(
            :body => build_body(extract_children(element, context))
          )

        when "do"
          # For some reason, blocks in |do| statements are of kind "unspec" but
          # they really should be "stmt". Thus we need to construct the
          # |StmtBlock| instance ourself.

          block_element = element.at_xpath("./block")

          AST::YCP::Do.new(
            :do    => if block_element
              AST::YCP::StmtBlock.new(
                :name       => nil,
                :symbols    => extract_symbols(block_element, context),
                :statements => extract_collection(block_element, "statements", context)
              )
            else
              nil
            end,
            :while => element_to_node(element.at_xpath("./while/*"), context)
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
          #
          # Note we make sure not to add arguments that would create duplicate
          # entries in the symbol table. These can arise e.g. if a variable with
          # the same name as an argument is defined inside the function (yes,
          # that's possible to do in YCP).
          unique_args = args.reject do |arg|
            block.symbols.find { |s| s.name == arg.name }
          end
          block.symbols = unique_args + block.symbols

          AST::YCP::FunDef.new(
            :name  => element["name"],
            :args  => args,
            :block => block
          )

        when "if"
          AST::YCP::If.new(
            :cond => element_to_node(element.elements[0], context),
            :then => if element.at_xpath("./then")
              element_to_node(element.at_xpath("./then"), context)
            else
              nil
            end,
            :else => if element.at_xpath("./else")
              element_to_node(element.at_xpath("./else"), context)
            else
              nil
            end
          )

        when "import"
          AST::YCP::Import.new(:name => element["name"])

        when "include"
          AST::YCP::Include.new(
            :name    => element["name"],
            :skipped => element["skipped"] == "1"
          )

        when "list"
          AST::YCP::List.new(
            :children => extract_children(element, :list)
          )

        when "locale"
          AST::YCP::Locale.new(:text => element["text"])

        when "map"
          AST::YCP::Map.new(
            :children => extract_children(element, :map)
          )

        when "repeat"
          # For some reason, blocks in |repeat| statements are of kind "unspec"
          # but they really should be "stmt". Thus we need to construct the
          # |StmtBlock| instance ourself.

          block_element = element.at_xpath("./do/block")

          AST::YCP::Repeat.new(
            :do    => if block_element
              AST::YCP::StmtBlock.new(
                :name       => nil,
                :symbols    => extract_symbols(block_element, context),
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
            :type     => AST::YCP::Type.new(element["type"]),
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
            :ns       => element["ns"],
            :name     => element["name"],
            :category => element["category"].to_sym,
            :type     => AST::YCP::Type.new(element["type"])
          )

        when "while"
          AST::YCP::While.new(
            :cond => element_to_node(element.at_xpath("./cond"), context),
            :do   => if element.at_xpath("./do/*")
              element_to_node(element.at_xpath("./do/*"), context)
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
            :type  => AST::YCP::Type.new(element["type"]),
            :child => element_to_node(element.elements[0], context)
          )

        when "yepropagate"
          AST::YCP::YEPropagate.new(
            :from  => AST::YCP::Type.new(element["from"]),
            :to    => AST::YCP::Type.new(element["to"]),
            :child => element_to_node(element.elements[0], context)
          )

        when "yereference"
          AST::YCP::YEReference.new(
            :child => element_to_node(element.elements[0], context)
          )

        when "yereturn"
          child = element_to_node(element.elements[0], context)

          if child.is_a?(AST::YCP::UnspecBlock) # ``{ ... }
            child
          else                                  # ``( ... )
            AST::YCP::YEReturn.new(
              :args    => [],
              :symbols => [],
              :child   => element_to_node(element.elements[0], context)
            )
          end

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

      transfer_comments(node, element)

      node
    end

    def extract_children(element, context)
      element.elements.map { |e| element_to_node(e, context) }
    end

    def extract_collection(element, name, context)
      child = element.at_xpath("./#{name}")
      child ? extract_children(child, context) : []
    end

    def extract_symbols(element, context)
      # We only want symbols of relevant categories in the AST. This simplifies
      # the code as it does not need to filter out the irrelevant ones.
      categories = [:variable, :reference, :function]

      all_symbols = extract_collection(element, "symbols", context)
      all_symbols.select { |s| categories.include?(s.category) }
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

    def toplevel_block?(element)
      element["kind"] == "file" || element["kind"] == "module"
    end

    def extract_file_statements(statements, file)
      extracted = []
      do_extract = false
      nesting_level = 0
      threshhold_level = nil

      statements.each do |statement|
        if statement.is_a?(AST::YCP::Include)
          extracted << statement if do_extract
          next if statement.skipped

          nesting_level += 1
          if statement.name == file
            do_extract = true
            threshhold_level = nesting_level
          end
        elsif statement.is_a?(AST::YCP::Filename)
          nesting_level -= 1
          if do_extract && nesting_level < threshhold_level
            do_extract = false
          end

          extracted << statement if do_extract
        else
          extracted << statement if do_extract
        end
      end

      extracted
    end

    def skip_include_statements(statements)
      filtered = []
      do_skip = false
      nesting_level = 0

      statements.each do |statement|
        if statement.is_a?(AST::YCP::Include)
          filtered << statement if nesting_level == 0
          next if statement.skipped

          nesting_level += 1
          do_skip = true
        elsif statement.is_a?(AST::YCP::Filename)
          nesting_level -= 1
          do_skip = false if nesting_level == 0
        else
          filtered << statement unless do_skip
        end
      end

      filtered
    end

    def transfer_comments(node, element)
      # We don't transfer comments consisting of only line whitespace. They
      # represent indentation, in-expression spacing, etc. -- things we would
      # ignore anyway later. By removing them here already we save some
      # processing time in later stages.

      comment_before = element["comment_before"]
      if comment_before && !is_line_whitespace?(comment_before)
        node.comment_before = comment_before
      end

      comment_after = element["comment_after"]
      if comment_after && !is_line_whitespace?(comment_after)
        node.comment_after = comment_after
      end
    end

    def is_line_whitespace?(s)
      s =~ /\A[ \t]*$\z/
    end
  end
end
