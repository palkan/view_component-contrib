# frozen_string_literal: true

module ViewComponentContrib
  class Railtie < Rails::Railtie
    config.view_component.preview_paths << File.join(ViewComponentContrib::APP_PATH, "views")

    initializer "view_component-contrib.skip_loading_previews_if_disabled" do
      unless Rails.application.config.view_component.show_previews
        previews = Rails.application.config.view_component.preview_paths.flat_map do |path|
          Pathname(path).glob("**/*preview.rb")
        end
        Rails.autoloaders.each { |autoloader| autoloader.ignore(previews) }
      end
    end
  end
end
