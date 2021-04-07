# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new

  RuboCop::RakeTask.new("rubocop:md") do |task|
    task.options << %w[-c .rubocop-md.yml]
  end
rescue LoadError
  task(:rubocop) {}
  task("rubocop:md") {}
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

namespace :test do
  task :isolated do
    Dir.glob("test/**/*_test.rb").all? do |file|
      sh(Gem.ruby, "-I#{__dir__}/lib:#{__dir__}/test", file)
    end || raise("Failures")
  end
end

desc "Run Ruby Next nextify"
task :nextify do
  sh "bundle exec ruby-next nextify -V"
end

desc "Generate installation template"
task :build_template do
  require_relative "app/templates/install/builder.rb"
  require "erb"

  builder = TemplateBuilder.new(File.join(__dir__, "app/templates/install"))
  contents = File.read(File.join(__dir__, "app/templates/install/template.rb"))

  puts ERB.new(contents).result(builder.get_binding)
end

task default: %w[rubocop rubocop:md test]
