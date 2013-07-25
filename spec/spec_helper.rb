# encoding: utf-8

require "y2r"

RSpec.configure do |c|
  c.color_enabled = true
end

def cleanup(s)
  s.split("\n").reject { |l| l =~ /^\s*$/ }.first =~ /^(\s*)/
  s.gsub(Regexp.new("^#{$1}"), "")[0..-2]
end

def compile_options
  {
    :module_paths  => [File.dirname(__FILE__) + "/modules"],
    :include_paths => [File.dirname(__FILE__) + "/include"]
  }
end
