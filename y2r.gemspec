# -*- encoding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + "/lib/y2r/version")

Gem::Specification.new do |s|
  s.name        = "y2r"
  s.version     = Y2R::VERSION
  s.summary     = "Transpiler translating YCP code into Ruby"
  s.description = <<-EOT.split("\n").map(&:strip).join(" ")
    Y2R is a transpiler translating YCP code into Ruby. YCP is a legacy language
    that is used internally in SUSE to write parts of YaST. This tool will help
    to get rid of it.
  EOT

  s.authors     = ["David Majda", "Josef Reidinger"]
  s.email       = ["dmajda@suse.cz", "jreidinger@suse.cz"]
  s.homepage    = "https://github.com/yast/y2r"
  s.license     = "MIT"

  s.files       = [
    "LICENSE",
    "README.md",
    "VERSION",
    "bin/y2r",
    "lib/y2r.rb",
    "lib/y2r/ast/ruby.rb",
    "lib/y2r/ast/ycp.rb",
    "lib/y2r/parser.rb",
    "lib/y2r/version.rb"
  ]
  s.executables = ["bin/y2r"]

  s.add_dependency "cheetah",  "0.3.0"
  s.add_dependency "docopt",   "0.5.0"
  s.add_dependency "nokogiri", "1.5.6"

  s.add_development_dependency "redcarpet"
  s.add_development_dependency "rspec"
end
