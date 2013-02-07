require "rspec/core/rake_task"

require File.expand_path(File.dirname(__FILE__) + "/spec/rspec_renderer")

file "spec/y2r_spec.rb" => "spec/y2r_spec.md" do |t|
  markdown = Redcarpet::Markdown.new(RSpecRenderer, :fenced_code_blocks => true)

  File.open(t.name, "w") do |f|
    f.write(markdown.render(File.read(t.prerequisites[0])))
  end
end

rule ".ybc" => ".ycp" do |t|
  ycpc = ENV["Y2R_YCPC"] || "ycpc"

  sh "#{ycpc} -c #{t.source}"
end

RSpec::Core::RakeTask.new
task :spec => ["spec/y2r_spec.rb", "spec/modules/String.ybc", "spec/modules/UI.ybc"]

task :default => :spec
