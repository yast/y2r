require "y2r"

RSpec.configure do |c|
  c.color_enabled = true
end

def cleanup(s)
  s =~ /^(\s*)/
  s.gsub(Regexp.new("^#{$1}"), "")[0..-2]
end
