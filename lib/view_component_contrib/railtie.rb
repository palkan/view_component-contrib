# frozen_string_literal: true

module ViewComponentContrib
  class Railtie < Rails::Railtie
    if !config.view_component.previews.nil?
      config.view_component.previews.paths << File.join(ViewComponentContrib::APP_PATH, "views")
    else
      config.view_component.preview_paths << File.join(ViewComponentContrib::APP_PATH, "views")
    end

    initializer "view_component-contrib.skip_loading_previews_if_disabled" do
      vc_config = Rails.application.config.view_component

      preview_enabled = (!vc_config.previews.nil?) ?
                          vc_config.previews.enabled :
                          vc_config.show_previews

      unless preview_enabled
        preview_paths = (!vc_config.previews.nil?) ?
                          vc_config.previews.paths :
                          vc_config.preview_paths

        previews = preview_paths.flat_map do |path|
          Pathname(path).glob("**/*preview.rb")
        end
        Rails.autoloaders.each { |autoloader| autoloader.ignore(previews) }
      end
    end
  end
end
