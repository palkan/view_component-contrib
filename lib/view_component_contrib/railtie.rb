# frozen_string_literal: true

module ViewComponentContrib
  class Railtie < Rails::Railtie
    config.view_component.preview_paths << File.join(ViewComponentContrib::APP_PATH, "views")
  end
end
