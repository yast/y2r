require File.expand_path(File.dirname(__FILE__) + "/y2r/ast")
require File.expand_path(File.dirname(__FILE__) + "/y2r/parser")
require File.expand_path(File.dirname(__FILE__) + "/y2r/version")

module Y2R
  def self.compile(input, options = {})
    Parser.new.parse(input, options).to_ruby
  end
end
