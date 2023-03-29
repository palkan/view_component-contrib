say "👋 Welcome to interactive ViewComponent installer and configurator. " \
    "Make sure you've read the view_component-contrib guide: https://github.com/palkan/view_component-contrib"

run "bundle add view_component view_component-contrib --skip-install"

say_status :info, "✅ ViewComponent gems added"

DEFAULT_ROOT = "app/frontend/components"

root = ask("Where do you want to store your view components? (default: #{DEFAULT_ROOT})")
ROOT_PATH = root.present? && root.downcase != "n" ? root : DEFAULT_ROOT

root_paths = ROOT_PATH.split("/").map { |path| "\"#{path}\"" }.join(", ")

application "config.view_component.preview_paths << Rails.root.join(#{root_paths})"
application "config.autoload_paths << Rails.root.join(#{root_paths})"

say_status :info, "✅ ViewComponent paths configured"

file "#{ROOT_PATH}/application_view_component.rb",
<%= code("./application_view_component.rb") %>

file "#{ROOT_PATH}/application_view_component_preview.rb",
<%= code("./application_view_component_preview.rb") %>

say_status :info, "✅ ApplicationViewComponent and ApplicationViewComponentPreview classes added"

USE_RSPEC = File.directory?("spec")
TEST_ROOT_PATH = USE_RSPEC ? File.join("spec", ROOT_PATH.sub("app/", "")) : File.join("test", ROOT_PATH.sub("app/", ""))

USE_DRY = yes? "Would you like to use dry-initializer in your component classes?"

if USE_DRY
  run "bundle add dry-initializer --skip-install"

  inject_into_file "#{ROOT_PATH}/application_view_component.rb", "\n  extend Dry::Initializer", after: "class ApplicationViewComponent < ViewComponentContrib::Base"

  say_status :info, "✅ Extended ApplicationViewComponent with Dry::Initializer"
end

initializer "view_component.rb",
<%= code("./initializer.rb") %>

say_status :info, "✅ Added ViewComponent initializer with required patches"

if USE_RSPEC
  inject_into_file "spec/rails_helper.rb", after: "require \"rspec/rails\"\n" do
    "require \"capybara/rspec\"\nrequire \"view_component/test_helpers\"\n"
  end

  inject_into_file "spec/rails_helper.rb", after: "RSpec.configure do |config|\n" do
    <<-CODE
  config.include ViewComponent::TestHelpers, type: :view_component
  config.include Capybara::RSpecMatchers, type: :view_component

  config.define_derived_metadata(file_path: %r{/#{TEST_ROOT_PATH}}) do |metadata|
    metadata[:type] = :view_component
  end

    CODE
  end
end

say_status :info, "✅ RSpec configured"

USE_WEBPACK = File.directory?("config/webpack") || File.file?("webpack.config.js")

if USE_WEBPACK
  USE_STIMULUS = yes? "Do you use StimulusJS?"

  if USE_STIMULUS
    file "#{ROOT_PATH}/index.js",
    <%= code("./index.stimulus.js") %>

    inject_into_file "#{ROOT_PATH}/application_view_component.rb", before: "\nend" do
      <%= code("./identifier.rb") %>
    end
  else
    file "#{ROOT_PATH}/index.js",
    <%= code("./index.js") %>
  end

  say_status :info, "✅ Added index.js to load components JS/CSS"
  say "⚠️   Don't forget to import component JS/CSS (#{ROOT_PATH}/index.js) from your application.js entrypoint"

  say "⚠️   Don't forget to add #{ROOT_PATH} to `additional_paths` in your `webpacker.yml` (unless your `source_path` already includes it)"

  USE_POSTCSS_MODULES = yes? "Would you like to use postcss-modules to isolate component styles?"

  if USE_POSTCSS_MODULES
    run "yarn add postcss-modules"

    if File.read("postcss.config.js").match(/plugins:\s*\[/)
      inject_into_file "postcss.config.js", after: "plugins: [" do
        <<-CODE

  require('postcss-modules')({
  <%= include("./postcss-modules.js") %>
  }),
        CODE
      end
    else
      inject_into_file "postcss.config.js", after: "plugins: {" do
        <<-CODE

  'postcss-modules': {
  <%= include("./postcss-modules.js") %>
  },
        CODE
      end
    end

    if !USE_STIMULUS
      inject_into_file "#{ROOT_PATH}/application_view_component.rb", before: "\nend" do
        <%= code("./identifier.rb") %>
      end
    end

    inject_into_file "#{ROOT_PATH}/application_view_component.rb", before: "\nend" do
      <%= code("./class_for.rb") %>
    end

    say_status :info, "✅ postcss-modules configured"
  end
else
  say "⚠️  See the discussion on how to configure non-Wepback JS/CSS installations: https://github.com/palkan/view_component-contrib/discussions/14"
end

<%= include("./generator.rb") %>

say "Installing gems..."

Bundler.with_unbundled_env { run "bundle install" }

say_status :info, "✅  You're ready to rock!"
