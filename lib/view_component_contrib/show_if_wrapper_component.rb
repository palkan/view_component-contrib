# frozen_string_literal: true

module ViewComponentContrib
  class ShowIfWrapperComponent < ViewComponent::Base
    # ShowIfWrapperComponent will only render if at least one of the
    # conditional fragments produces output.
    # A conditional fragment is declared by wrapping markup in a
    # `show_if` block.

    attr_reader :conditional_fragments

    def before_render
      @captured_content = content
    end

    def initialize
      @conditional_fragments = []
    end

    def call
      @captured_content if conditions_passed?
    end

    # Call this inside the template:  = w.show_if { … }
    # Captures the block, pushes it into the list, and
    # returns the HTML string so it appears inline where it was declared
    def show_if(&block)
      view_context.capture(&block).tap do |html|
        conditional_fragments << html
      end
    end

    # Render the wrapper itself only if:
    #   - at least one conditional fragment produced output, OR
    #   - no conditional fragments were declared
    def conditions_passed?
      conditional_fragments.empty? || conditional_fragments.any?(&:present?)
    end
  end
end
