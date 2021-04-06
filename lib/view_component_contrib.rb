# frozen_string_literal: true

require "ruby-next/language/setup"
RubyNext::Language.setup_gem_load_path

module ViewComponentContrib
  APP_PATH = File.expand_path(File.join(__dir__, "../app"))

  autoload :TranslationHelper, "view_component_contrib/translation_helper"

  autoload :Base, "view_component_contrib/base"
  autoload :Preview, "view_component_contrib/preview"
end

require "view_component_contrib/version"
