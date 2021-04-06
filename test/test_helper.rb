# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] = "test"

require "combustion"

require "view_component/engine"
require "view_component_contrib/engine"

Combustion.path = "test/internal"
Combustion.initialize! :action_controller, :action_view do
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
  config.log_level = :fatal

  config.view_component.show_previews = true

  config.autoload_paths << Rails.root.join("app", "frontend", "components")
  config.view_component.preview_paths << Rails.root.join("app", "frontend", "components")
end

class ApplicationController < ActionController::Base
end

require "minitest/autorun"
require "minitest/focus"
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ViewTestCase < Minitest::Test
  include ViewComponent::TestHelpers
end
