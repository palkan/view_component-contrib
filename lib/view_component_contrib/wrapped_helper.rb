# frozen_string_literal: true

module ViewComponentContrib
  # Adds `#wrapped` method to automatically wrap self into a WrapperComponent
  module WrappedHelper
    def wrapped
      WrapperComponent.new(self)
    end
  end
end
