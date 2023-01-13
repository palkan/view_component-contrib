# frozen_string_literal: true

require "test_helper"

class SidecarTranslationHelperTest < ViewTestCase
  def setup
    I18n.backend.store_translations(
      :en,
      view_components: {
        sidecar_translation_helper_test: {
          test: {
            msg: "Hello from contrib"
          }
        }
      }
    )
  end

  def teardown
    I18n.backend.reload!
  end

  module Test
    class Component < ViewComponent::Base
      include(ViewComponent::Translatable) unless ancestors.include?(ViewComponent::Translatable)
      include ViewComponentContrib::TranslationHelper

      def initialize(source = :sidecar)
        @source = source
      end

      def call
        if @source == :sidecar
          "<div>#{t(".message")}</div>"
        else
          "<div>#{t(".msg")}</div>"
        end
      end
    end
  end

  def test_translate_from_sidecar
    component = Test::Component.new

    render_inline(component)

    assert_selector "div", count: 1, text: "Hello from sidecar"
  end

  def test_translate_from_contrib
    component = Test::Component.new(:contrib)

    render_inline(component)

    assert_selector "div", count: 1, text: "Hello from contrib"
  end
end
