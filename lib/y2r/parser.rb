require "cheetah"
require "rexml/document"
require "tempfile"

module Y2R
  class Parser
    class SyntaxError < StandardError
    end

    # Sorted alphabetically.
    ELEMENT_INFO = {
      :assign      => { :type => :wrapper },
      :builtin     => { :type => :collection, :create_context => :builtin },
      :compare     => { :type => :struct },
      :fun_def     => { :type => :struct },
      :list        => { :type => :collection, :create_context => :list, :filter => [:size] },
      :map         => { :type => :collection, :create_context => :map, :filter => [:size] },
      :return      => { :type => :wrapper },
      :symbol      => {
        :type   => :leaf,
        :filter => proc { |e|
          if e.attributes["category"] == "filename"
            [:global, :category, :type, :name]
          else
            [:global, :category, :type]
          end
        }
      },
      :while       => { :type => :struct },
      :yeterm      => { :type => :collection, :create_context => :yeterm, :filter => [:args] },
      :yetriple    => { :type => :struct },
      :yeunary     => { :type => :wrapper }
    }

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
            cmd = "ycpc", "-c", "-x", "-o", xml_file.path
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
        when "cond", "declaration", "do", "else", "expr", "false", "key", "lhs",
             "rhs", "stmt", "then", "true", "value", "ycp"
          return element_to_node(element.elements[1], context)
        when "block"
          return AST::Block.new(
            :kind       => element.attributes["kind"],
            :symbols    => extract_collection(element, "symbols", context),
            :statements => extract_collection(element, "statements", context)
          )
        when "call"
          return AST::Call.new(
            :ns   => element.attributes["ns"],
            :name => element.attributes["name"],
            :args => extract_collection(element, "args", context)
          )
        when "const"
          return AST::Const.new(
            :type  => element.attributes["type"],
            :value => element.attributes["value"]
          )
        when "element"
          if context != :map
            return element_to_node(element.elements[1], context)
          else
            return AST::MapElement.new(
              :key   => element_to_node(element.elements["key"], context),
              :value => element_to_node(element.elements["value"], context)
            )
          end
        when "if"
          return AST::If.new(
            :cond => element_to_node(element.elements[1], context),
            :then => element_to_node(element.elements[2], context),
            :else => if element.elements.size > 2
              element_to_node(element.elements[3], context)
            else
              nil
            end
          )
        when "import"
          return AST::Import.new(:name => element.attributes["name"])
        when "locale"
          return AST::Locale.new(:text => element.attributes["text"])
        when "textdomain"
          return AST::Textdomain.new(:name => element.attributes["name"])
        when "variable"
          return AST::Variable.new(:name => element.attributes["name"])
        when "yebinary"
          return AST::YEBinary.new(
            :name => element.attributes["name"],
            :lhs  => element_to_node(element.elements[1], context),
            :rhs  => element_to_node(element.elements[2], context)
          )
        when "yebracket"
          return AST::YEBracket.new(
            :value   => element_to_node(element.elements[1], context),
            :index   => element_to_node(element.elements[2], context),
            :default => element_to_node(element.elements[3], context)
          )
      end

      info = ELEMENT_INFO[element.name.to_sym]
      raise "Invalid element: <#{element.name}>." unless info

      if info[:contexts]
        raise "Element <#{element.name}> appeared out of context." unless context
        unless info[:contexts][context]
          raise "Element <#{element.name}> appeared in unexpected context \"#{context}\"."
        end
        info = info[:contexts][context]
        class_name_prefix = classify(context.to_s)
      else
        class_name_prefix = ""
      end

      class_name_base = classify(element.name)
      node = AST.const_get(class_name_prefix + class_name_base).new

      filter = if info[:filter]
        info[:filter].is_a?(Proc) ? info[:filter].call(element) : info[:filter]
      else
        []
      end

      element.attributes.each do |name, value|
        node.send("#{name}=", value) unless filter.include?(name.to_sym)
      end

      context = info[:create_context] if info[:create_context]

      case info[:type]
        when :leaf
          # Don't do nothing, we're done.

        when :wrapper
          child = element.elements[1]
          node.child = child ? element_to_node(child, context) : nil

        when :collection
          node.children = element.elements.map do |element|
            element_to_node(element, context)
          end

        when :struct
          element.elements.each do |element|
            unless filter.include?(element.name.to_sym)
              node.send("#{element.name}=", element_to_node(element, context))
            end
          end

        else
          raise "Invalid node type: #{info[:type]}."
      end

      node
    end

    def classify(s)
      s.sub(/^(ycp|ye.|.)/) { |s| s.upcase }.gsub(/_./) { |s| s[1].upcase }
    end

    def extract_collection(element, name, context)
      if element.elements[name]
        element.elements[name].elements.map do |element|
          element_to_node(element, context)
        end
      else
        []
      end
    end
  end
end
