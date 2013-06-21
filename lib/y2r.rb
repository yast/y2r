# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ruby")
require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ycp")
require File.expand_path(File.dirname(__FILE__) + "/y2r/parser")
require File.expand_path(File.dirname(__FILE__) + "/y2r/version")

module Y2R
  def self.compile(input, options = {})
    ycp_context = AST::YCP::Context.new(
      :export_private            => options[:export_private],
      :as_include_file           => options[:as_include_file],
      :dont_inline_include_files => options[:dont_inline_include_files]
    )
    ruby_context = AST::Ruby::EmitterContext.new(:width => 80, :shift => 0)

    Parser.new(options).parse(input).compile(ycp_context).to_ruby(ruby_context)
  end
end
