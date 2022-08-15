# frozen_string_literal: true

require "test_helper"

ActiveSupport.on_load(:view_component) do
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
end

class PreviewsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Warmup previews
    ViewComponent::Preview.all
  end

  def test_previews_index_show_sidecar_preview
    get "/rails/view_components"

    assert_select "a", "Banner"
  end

  def test_previews_index_does_not_show_abstract_previews
    get "/rails/view_components"

    assert_select "a", text: "Application View Component Preview", count: 0
  end

  def test_preview_with_implicit_component_and_template
    get "/rails/view_components/banner/default"

    assert_select "div", text: "Welcome!"
  end

  def test_preview_with_explicit_component_and_implicit_template
    get "/rails/view_components/banner/alert"

    assert_select "div", text: "Alarma!"
  end

  def test_preview_with_explicit_component_and_container_class
    get "/rails/view_components/banner/wide"

    assert_select "div.w-full", text: "Wide"
  end

  def test_preview_with_explicit_root_template
    get "/rails/view_components/custom_banner/default"

    assert_select "div", text: "Custom banner"
  end

  def test_preview_with_explicit_example_template
    get "/rails/view_components/custom_banner/example"

    assert_select "div", text: "Example banner"
  end
end
