# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ruby")
require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ycp")
require File.expand_path(File.dirname(__FILE__) + "/y2r/parser")
require File.expand_path(File.dirname(__FILE__) + "/y2r/version")

module Y2R
  def self.compile(input, options = {})
    ast = Parser.new(options).parse(input)

    if !options[:xml]
      ycp_context = AST::YCP::CompilerContext.new(
        :blocks     => [],
        :whitespace => AST::YCP::Comments::Whitespace::DROP_ALL,
        :options    => options,
        :elsif      => false
      )
      ruby_context = AST::Ruby::EmitterContext.new(:width => 80, :shift => 0)

      ast.compile(ycp_context).to_ruby(ruby_context)
    else
      ast
    end
  end
end
