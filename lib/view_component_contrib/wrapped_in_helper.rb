# frozen_string_literal: true

module ViewComponentContrib
  # Adds `#wrapped_in` method to register a component with a wrapper
  module WrappedInHelper
    def wrapped_in(wrapper)
      raise ArgumentError, "Expected a ViewComponentContrib::WrapperComponent" unless wrapper.is_a?(WrapperComponent)

      wrapper.register(self)
      self
    end
  end
end
