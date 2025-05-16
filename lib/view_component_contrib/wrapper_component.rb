# frozen_string_literal: true

module ViewComponentContrib
  # WrapperComponent allows to wrap any component with a custom HTML code.
  # The whole wrapper is only rendered when the child component.render? returns true.
  # Thus, wrapper could be used to conditionally render the outer html for components without
  # conditionals in templates.
  class WrapperComponent < ViewComponent::Base
    include WrappedInHelper

    class DoubleRenderError < StandardError
      def initialize(component)
        super("A child component could only be rendered once within a wrapper: #{component}")
      end
    end

    class ComponentPresentError < StandardError
      def initialize
        super("A wrapper component cannot register a component if it already has a component from the constructor")
      end
    end

    attr_reader :component_instance, :registered_components

    # We need to touch `content` before the `render?` method is called,
    # otherwise children calling `.wrapped_in` won't be registered.
    # This overrides the default lazy evaluation of `content` in ViewComponent,
    # but it's necessary for the wrapper to work properly.
    def before_render
      content if component_instance.blank?
    end

    def initialize(component = nil)
      @component_instance = component
      @registered_components = []
    end

    def render?
      return component_instance.render? if component_instance.present?

      registered_components.any?(&:render?)
    end

    # Simply return the contents of the block passed to #render_component.
    # (Alias couldn't be used here 'cause ViewComponent check for the method presence when
    # choosing between #call and a template.)
    def call
      content
    end

    # Returns rendered child component
    # The name component is chosen for convenient usage in templates,
    # so we can simply call `= wrapper.component` in the place where we're going
    # to put the component
    def component
      raise DoubleRenderError, component_instance if @rendered

      @rendered = component_instance.render_in(view_context).html_safe
    end

    # Register a component to be rendered within the wrapper.
    # If no registered components render, the wrapper itself won't be rendered.
    def register(component)
      raise ComponentPresentError if component_instance.present?
      raise ArgumentError, "Expected a ViewComponent" unless component.is_a?(ViewComponent::Base)

      registered_components << component
    end
  end
end
