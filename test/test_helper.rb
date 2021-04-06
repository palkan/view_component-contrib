# frozen_string_literal: true

begin
  require "pry-byebug"
rescue LoadError
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

ENV["RAILS_ENV"] = "test"

require "combustion"

require "view_component"
require "view_component-contrib"

Combustion.initialize! :action_controller, :action_view

class ApplicationController < ActionController::Base
end

require "minitest/autorun"

class ViewTestCase < Minitest::Test
  include ViewComponent::TestHelpers
end
