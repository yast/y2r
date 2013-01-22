require "y2r"

RSpec.configure do |c|
  c.color_enabled = true
end

def cleanup(s)
  s =~ /^(\s*)/
  prefix = $1

  s.split("\n").map { |line| line.sub(prefix, "") }.join("\n").strip
end
