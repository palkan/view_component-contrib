# frozen_string_literal: true

module ViewComponentContrib
  # WrapperComponent allwows to wrap any component with a custom HTML code.
  # The whole wrapper is only rendered when the child component.render? returns true.
  # Thus, wrapper could be used to conditionally render the outer html for components without
  # conditionals in templates.
  class WrapperComponent < ViewComponent::Base
    class DoubleRenderError < StandardError
      def initialize(component)
        super("A child component could only be rendered once within a wrapper: #{component}")
      end
    end

    attr_reader :component_instance

    delegate :render?, to: :component_instance

    def initialize(component)
      @component_instance = component
    end

    # Simply return the contents of the block passed to #render_component.
    # (Alias couldn't be used here 'cause ViewComponent check for the method presence when
    # choosing between #call and a template.)
    def call
      content
    end

    # Returns rendered child component
    # The name component is chosen for convienent usage in templates,
    # so we can simply call `= wrapper.component` in the place where we're going
    # to put the component
    def component
      raise DoubleRenderError, component_instance if @rendered

      @rendered = component_instance.render_in(view_context).html_safe
    end
  end
end
