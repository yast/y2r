# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ruby")
require File.expand_path(File.dirname(__FILE__) + "/y2r/ast/ycp")
require File.expand_path(File.dirname(__FILE__) + "/y2r/parser")
require File.expand_path(File.dirname(__FILE__) + "/y2r/version")

module Y2R
  def self.compile(input, options = {})
    context = AST::YCP::Context.new(:export_private => options[:export_private])

    Parser.new.parse(input, options).compile(context).to_ruby
  end
end
