# frozen_string_literal: true

require_relative "boot"
require "action_controller/railtie"

module Dummy
  class Application < Rails::Application
    config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
    config.log_level = :fatal
    config.eager_load = true
  end
end
