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
  require_relative "app/templates/install/builder"
  require "erb"

  builder = TemplateBuilder.new(File.join(__dir__, "app/templates/install"))
  contents = File.read(File.join(__dir__, "app/templates/install/template.rb"))

  ERB.new(contents).result(builder.get_binding).tap do |template|
    puts template
  end
end

desc "Push installation template to RailsBytes"
task :publish_template do
  require "net/http"
  require "json"

  token, account_id = ENV.fetch("RAILS_BYTES_TOKEN"), ENV.fetch("RAILS_BYTES_ACCOUNT_ID")

  template_id = "zJosO5"
  uri = URI("https://railsbytes.com/api/v1/accounts/#{account_id}/templates/#{template_id}.json")
  request = Net::HTTP::Patch.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request.content_type = "application/json"

  tmpl = Rake::Task["build_template"].execute.first.call
  request.body = JSON.dump(script: tmpl)

  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
end

task default: %w[rubocop rubocop:md test]
