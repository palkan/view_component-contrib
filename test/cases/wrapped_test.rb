# frozen_string_literal: true

require "test_helper"

class WrapperComponentTest < ViewTestCase
  class Component < ViewComponentContrib::Base
    attr_reader :should_render

    def initialize(should_render: true)
      @should_render = should_render
    end

    alias_method :render?, :should_render

    def call
      "Hello from test".html_safe
    end
  end

  def test_render
    component = Component.new.wrapped

    render_inline(component) do |wrapper|
      "<div>#{wrapper.component}</div>".html_safe
    end

    assert_selector "div", count: 1, text: "Hello from test"
  end

  def test_does_not_render_when_component_should_not_render
    component = Component.new(should_render: false).wrapped

    render_inline(component) do |wrapper|
      "<div>#{wrapper.component}</div>".html_safe
    end

    assert_no_selector page, "div"
  end

  def test_double_render
    component = Component.new.wrapped

    assert_raises ViewComponentContrib::WrapperComponent::DoubleRenderError do
      render_inline(component) do |wrapper|
        "<li>#{wrapper.component}</li><li>#{wrapper.component}</li>".html_safe
      end
    end
  end
end
