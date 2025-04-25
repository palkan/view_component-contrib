# frozen_string_literal: true

require "test_helper"

class ShowIfWrapperComponentTest < ViewTestCase
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

  def test_renders_when_two_inner_components_render
    inner_component_a = Component.new
    inner_component_b = Component.new
    wrapper_component = ViewComponentContrib::ShowIfWrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{wrapper.show_if { render_inline(inner_component_a).to_html }}</div>" \
      "<div>#{wrapper.show_if { render_inline(inner_component_b).to_html }}</div>".html_safe
    end

    assert_selector page, "h3", count: 1, text: "Title"
    assert_selector page, "div", count: 2
    assert_selector page, "div", text: "Hello from test", count: 2
  end

  def test_renders_when_one_inner_component_renders
    inner_component_a = Component.new
    inner_component_b = Component.new(should_render: false)
    wrapper_component = ViewComponentContrib::ShowIfWrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{wrapper.show_if { render_inline(inner_component_a).to_html }}</div>" \
      "<div>#{wrapper.show_if { render_inline(inner_component_b).to_html }}</div>".html_safe
    end

    assert_selector page, "h3", count: 1, text: "Title"
    assert_selector page, "div", count: 2
    assert_selector page, "div", text: "Hello from test", count: 1
  end

  def test_does_not_render_when_no_inner_components_render
    inner_component_a = Component.new(should_render: false)
    inner_component_b = Component.new(should_render: false)
    wrapper_component = ViewComponentContrib::ShowIfWrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{wrapper.show_if { render_inline(inner_component_a).to_html }}</div>" \
      "<div>#{wrapper.show_if { render_inline(inner_component_b).to_html }}</div>".html_safe
    end

    assert_no_selector page, "h3"
    assert_no_selector page, "div"
  end
end
