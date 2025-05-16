# frozen_string_literal: true

require "test_helper"

class WrappedInTest < ViewTestCase
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

  class NonViewComponent
    include ViewComponentContrib::WrappedInHelper

    def call
      "Hello from test".html_safe
    end
  end

  def test_renders_when_inner_component_renders
    inner_component = Component.new
    wrapper_component = ViewComponentContrib::WrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{render_inline(inner_component.wrapped_in(wrapper)).to_html}</div>".html_safe
    end

    assert_selector page, "h3", count: 1, text: "Title"
    assert_selector page, "div", text: "Hello from test", count: 1
  end

  def test_renders_when_two_inner_components_render
    inner_component_a = Component.new
    inner_component_b = Component.new
    wrapper_component = ViewComponentContrib::WrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{render_inline(inner_component_a.wrapped_in(wrapper)).to_html}</div>" \
      "<div>#{render_inline(inner_component_b.wrapped_in(wrapper)).to_html}</div>".html_safe
    end

    assert_selector page, "h3", count: 1, text: "Title"
    assert_selector page, "div", count: 2
    assert_selector page, "div", text: "Hello from test", count: 2
  end

  def test_renders_when_one_inner_component_renders
    inner_component_a = Component.new
    inner_component_b = Component.new(should_render: false)
    wrapper_component = ViewComponentContrib::WrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{render_inline(inner_component_a.wrapped_in(wrapper)).to_html}</div>" \
      "<div>#{render_inline(inner_component_b.wrapped_in(wrapper)).to_html}</div>".html_safe
    end

    assert_selector page, "h3", count: 1, text: "Title"
    assert_selector page, "div", count: 2
    assert_selector page, "div", text: "Hello from test", count: 1
  end

  def test_does_not_render_when_no_inner_components_render
    inner_component_a = Component.new(should_render: false)
    inner_component_b = Component.new(should_render: false)
    wrapper_component = ViewComponentContrib::WrapperComponent.new

    render_inline(wrapper_component) do |wrapper|
      "<h3>Title</h3>" \
      "<div>#{render_inline(inner_component_a.wrapped_in(wrapper)).to_html}</div>" \
      "<div>#{render_inline(inner_component_b.wrapped_in(wrapper)).to_html}</div>".html_safe
    end

    assert_no_selector page, "h3"
    assert_no_selector page, "div"
  end

  def test_outer_wrapper_renders_when_one_inner_wrapper_renders
    inner_components_a = [Component.new, Component.new(should_render: false)]
    inner_components_b = [Component.new(should_render: false), Component.new(should_render: false)]
    inner_wrapper_component_a = ViewComponentContrib::WrapperComponent.new
    inner_wrapper_component_b = ViewComponentContrib::WrapperComponent.new
    outer_wrapper_component = ViewComponentContrib::WrapperComponent.new

    render_inline(outer_wrapper_component) do |outer_wrapper|
      "<h3>Title</h3>" \
      "#{
        render_inline(inner_wrapper_component_a.wrapped_in(outer_wrapper)) do |inner_wrapper_a|
          "<h3>Subtitle A</h3>" \
          "<div>#{render_inline(inner_components_a[0].wrapped_in(inner_wrapper_a)).to_html}</div>" \
          "<div>#{render_inline(inner_components_a[1].wrapped_in(inner_wrapper_a)).to_html}</div>".html_safe
        end
      }" \
      "#{
        render_inline(inner_wrapper_component_b.wrapped_in(outer_wrapper)) do |inner_wrapper_b|
          "<h3>Subtitle B</h3>" \
          "<div>#{render_inline(inner_components_b[0].wrapped_in(inner_wrapper_b)).to_html}</div>" \
          "<div>#{render_inline(inner_components_b[1].wrapped_in(inner_wrapper_b)).to_html}</div>".html_safe
        end
      }".html_safe
    end

    assert_selector page, "h3", count: 1, text: "Title"
    assert_selector page, "h3", count: 1, text: "Subtitle A"
    assert_no_selector page, "h3", text: "Subtitle B"
    assert_selector page, "div", text: "Hello from test", count: 1
  end

  def test_outer_wrapper_does_not_render_when_no_inner_wrappers_render
    inner_components_a = [Component.new(should_render: false), Component.new(should_render: false)]
    inner_components_b = [Component.new(should_render: false), Component.new(should_render: false)]
    inner_wrapper_component_a = ViewComponentContrib::WrapperComponent.new
    inner_wrapper_component_b = ViewComponentContrib::WrapperComponent.new
    outer_wrapper_component = ViewComponentContrib::WrapperComponent.new

    render_inline(outer_wrapper_component) do |outer_wrapper|
      "<h3>Title</h3>" \
      "#{
        render_inline(inner_wrapper_component_a.wrapped_in(outer_wrapper)) do |inner_wrapper_a|
          "<h3>Subtitle A</h3>" \
          "<div>#{render_inline(inner_components_a[0].wrapped_in(inner_wrapper_a)).to_html}</div>" \
          "<div>#{render_inline(inner_components_a[1].wrapped_in(inner_wrapper_a)).to_html}</div>".html_safe
        end
      }" \
      "#{
        render_inline(inner_wrapper_component_b.wrapped_in(outer_wrapper)) do |inner_wrapper_b|
          "<h3>Subtitle B</h3>" \
          "<div>#{render_inline(inner_components_b[0].wrapped_in(inner_wrapper_b)).to_html}</div>" \
          "<div>#{render_inline(inner_components_b[1].wrapped_in(inner_wrapper_b)).to_html}</div>".html_safe
        end
      }".html_safe
    end

    assert_no_selector page, "h3"
    assert_no_selector page, "div"
  end

  def test_raises_error_when_passing_non_wrapper_component
    component_a = Component.new
    component_b = Component.new

    assert_raises(ArgumentError) do
      component_a.wrapped_in(component_b)
    end
  end

  def test_raises_error_when_passing_non_view_component
    non_view_component = NonViewComponent.new
    wrapper_component = ViewComponentContrib::WrapperComponent.new

    assert_raises(ArgumentError) do
      non_view_component.wrapped_in(wrapper_component)
    end
  end
end
