# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ruby")
require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ycp")
require File.expand_path(File.dirname(__FILE__) + "/y2r/parser")
require File.expand_path(File.dirname(__FILE__) + "/y2r/version")

module Y2R
  def self.compile(input, options = {})
    ycp_context = AST::YCP::Context.new(
      :export_private => options[:export_private],
      :include_file   => options[:include_file]
    )
    ruby_context = AST::Ruby::Context.new(:width => 80, :shift => 0)

    Parser.new.parse(input, options).compile(ycp_context).to_ruby(ruby_context)
  end
end
