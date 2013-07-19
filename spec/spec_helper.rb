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
  module_paths = if ENV["Y2R_MODULE_PATH"]
    ENV["Y2R_MODULE_PATH"].split(":")
  else
    [File.dirname(__FILE__) + "/modules"]
  end

  include_paths = if ENV["Y2R_INCLUDE_PATH"]
    ENV["Y2R_INCLUDE_PATH"].split(":")
  else
    [File.dirname(__FILE__) + "/include"]
  end

  {
    :module_paths  => module_paths,
    :include_paths => include_paths
  }
end
