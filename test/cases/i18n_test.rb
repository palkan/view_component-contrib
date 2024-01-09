# frozen_string_literal: true

require "test_helper"

class TranslationHelperTest < ViewTestCase
  def setup
    I18n.backend.store_translations(
      :en,
      view_components: {
        translation_helper_test: {
          test: {
            message: "Hello from test"
          }
        }
      },
      components: {
        my_test: {
          component: {
            message: "Hello from custom"
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

      def call
        "<div>#{t(".message")}</div>".html_safe
      end
    end
  end

  module Custom
    class Component < ViewComponentContrib::Base
      self.i18n_namespace = "components"
      self.i18n_scope = %w[my_test component]

      def call
        "<div>#{t(".message")}</div>".html_safe
      end
    end
  end

  def test_translate
    component = Test::Component.new

    render_inline(component)

    assert_selector "div", count: 1, text: "Hello from test"
  end

  def test_translate_with_custom_config
    component = Custom::Component.new

    render_inline(component)

    assert_selector "div", count: 1, text: "Hello from custom"
  end
end
