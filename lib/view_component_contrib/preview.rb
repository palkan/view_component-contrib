# frozen_string_literal: true

module ViewComponentContrib
  module Preview
    autoload :Base, "view_component_contrib/preview/base"

    autoload :Abstract, "view_component_contrib/preview/abstract"
    autoload :DefaultTemplate, "view_component_contrib/preview/default_template"
    autoload :Sidecarable, "view_component_contrib/preview/sidecarable"
  end
end
