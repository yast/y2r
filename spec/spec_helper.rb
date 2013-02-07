require "y2r"

RSpec.configure do |c|
  c.color_enabled = true
end

def cleanup(s)
  s =~ /^(\s*)/
  s.gsub(Regexp.new("^#{$1}"), "")[0..-2]
end

def compile_options
  {
    :ycpc         => ENV["Y2R_YCPC"],
    :module_path  => ENV["Y2R_MODULE_PATH"] || File.dirname(__FILE__) + "/modules",
    :include_path => ENV["Y2R_INCLUDE_PATH"]
  }
end
