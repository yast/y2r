require "cheetah"
require "rexml/document"
require "tempfile"

module Y2R
  class Parser
    class SyntaxError < StandardError
    end

    # Sorted alphabetically.
    ELEMENT_INFO = {
      :assign     => { :type => :wrapper,    :class => AST::Assign,     :filter => []                                 },
      :block      => { :type => :struct,     :class => AST::Block,      :filter => []                                 },
      :const      => { :type => :leaf,       :class => AST::Const,      :filter => []                                 },
      :element    => { :type => :wrapper,    :class => AST::Element,    :filter => []                                 },
      :list       => { :type => :collection, :class => AST::List,       :filter => [:size]                            },
      :statements => { :type => :collection, :class => AST::Statements, :filter => []                                 },
      :stmt       => { :type => :wrapper,    :class => AST::Stmt,       :filter => []                                 },
      :symbol     => { :type => :leaf,       :class => AST::Symbol,     :filter => [:global, :category, :type, :name] },
      :symbols    => { :type => :collection, :class => AST::Symbols,    :filter => []                                 },
      :ycp        => { :type => :wrapper,    :class => AST::YCP,        :filter => [:version]                         }
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

    def element_to_node(element)
      info = ELEMENT_INFO[element.name.to_sym]
      raise "Invalid element: <#{element.name}>." unless info

      node = info[:class].new

      element.attributes.each do |name, value|
        node.send("#{name}=", value) unless info[:filter].include?(name.to_sym)
      end

      case info[:type]
        when :leaf
          # Don't do nothing, we're done.

        when :wrapper
          node.child = element_to_node(element.elements[1])

        when :collection
          node.children = element.elements.map { |e| element_to_node(e) }

        when :struct
          element.elements.each do |element|
            unless info[:filter].include?(element.name.to_sym)
              node.send("#{element.name}=", element_to_node(element))
            end
          end

        else
          raise "Invalid node type: #{info[:type]}."
      end

      node
    end
  end
end
