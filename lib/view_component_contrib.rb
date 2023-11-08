# frozen_string_literal: true

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path

require "view_component"

module ViewComponentContrib
  APP_PATH = File.expand_path(File.join(__dir__, "../app"))

  autoload :TranslationHelper, "view_component_contrib/translation_helper"
  autoload :WrapperComponent, "view_component_contrib/wrapper_component"
  autoload :WrappedHelper, "view_component_contrib/wrapped_helper"
  autoload :StyleVariants, "view_component_contrib/style_variants"

  autoload :Base, "view_component_contrib/base"
  autoload :Preview, "view_component_contrib/preview"
end

require "view_component_contrib/railtie" if defined?(::Rails::Railtie)
require "view_component_contrib/version"
