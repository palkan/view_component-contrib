# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ruby-next/language/runtime" unless ENV["CI"]

ENV["RAILS_ENV"] = "test"

# https://github.com/rails/rails/issues/54263
require "logger"
require "combustion"
require "view_component_contrib"

Combustion.path = "test/internal"
Combustion.initialize! :action_controller, :action_view do
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
  config.log_level = :fatal

  config.view_component.previews.enabled = true

  config.autoload_paths << Rails.root.join("app", "frontend", "components")
  config.view_component.previews.paths << Rails.root.join("app", "frontend", "components")
  config.view_component.previews.paths << Rails.root.join("app", "frontend", "previews")
end

class ApplicationController < ActionController::Base
end

require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "action_controller/test_case"
class ViewTestCase < Minitest::Test
  include ViewComponent::TestHelpers
end

# rbytes is only available for Ruby 3.0+
begin
  require "rbytes"
  require "ruby_bytes/test_case"

  class GeneratorTestCase < RubyBytes::TestCase
    root File.join(__dir__, "../templates/install")
    dummy_app File.join(__dir__, "fixtures", "basic_rails_app")
  end
rescue LoadError
end
