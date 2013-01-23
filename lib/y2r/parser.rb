require "cheetah"
require "rexml/document"
require "tempfile"

module Y2R
  class Parser
    class SyntaxError < StandardError
    end

    # Sorted alphabetically.
    ELEMENT_INFO = {
      :assign     => { :type => :wrapper },
      :block      => { :type => :struct },
      :const      => { :type => :leaf },
      :element    => {
        :contexts => {
          :list => { :type => :wrapper },
          :map  => { :type => :struct  }
        }
      },
      :key        => { :type => :wrapper },
      :list       => { :type => :collection, :create_context => :list, :filter => [:size] },
      :map        => { :type => :collection, :create_context => :map, :filter => [:size] },
      :statements => { :type => :collection },
      :stmt       => { :type => :wrapper },
      :symbol     => { :type => :leaf, :filter => [:global, :category, :type, :name] },
      :symbols    => { :type => :collection },
      :value      => { :type => :wrapper },
      :ycp        => { :type => :wrapper, :filter => [:version] }
    }

    def parse(input)
      xml_to_ast(ycp_to_xml(input))
    end

    private

    def ycp_to_xml(ycp)
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
            Cheetah.run("ycpc", "-c", "-x", "-o", xml_file.path, ycp_file.path)
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
      info = ELEMENT_INFO[element.name.to_sym]
      raise "Invalid element: <#{element.name}>." unless info

      if info[:contexts]
        raise "Element <#{element.name}> appeared out of context." if !context
        unless info[:contexts][context]
          raise "Element <#{element.name}> appeared in unexpected context \"#{context}\"."
        end
        class_name_prefix = context.to_s.sub(/^./) { |ch| ch.upcase }
        info = info[:contexts][context]
      else
        class_name_prefix = ""
      end

      class_name = class_name_prefix +
        element.name.sub(/^ycp/, "YCP").sub(/^./) { |ch| ch.upcase }
      node = AST.const_get(class_name).new

      filter = info[:filter] || []

      element.attributes.each do |name, value|
        node.send("#{name}=", value) unless filter.include?(name.to_sym)
      end

      context = info[:create_context] if info[:create_context]

      case info[:type]
        when :leaf
          # Don't do nothing, we're done.

        when :wrapper
          node.child = element_to_node(element.elements[1], context)

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
  end
end
