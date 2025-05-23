# frozen_string_literal: true

require "test_helper"

class StyledComponentTest < ViewTestCase
  class Component < ViewComponentContrib::Base
    include ViewComponentContrib::StyleVariants

    erb_template <<~ERB
      <div class="<%= style(theme: theme, size: size, disabled: disabled) %>">Hello</div>
    ERB

    style do
      base { %w[flex flex-col] }

      variants {
        theme {
          primary { %w[primary-color primary-bg] }
          secondary { %w[secondary-color secondary-bg] }
        }
        size {
          sm { %w[text-sm] }
          md { %w[text-md] }
          lg { %w[text-lg] }
        }
        disabled {
          yes { "opacity-50" }
        }
      }

      defaults { {theme: :primary, size: :sm} }
    end

    attr_reader :theme, :size, :disabled

    def initialize(theme: :primary, size: :md, disabled: false)
      @theme = theme
      @size = size
      @disabled = disabled
    end
  end

  def test_render_variants
    component = Component.new

    render_inline(component)

    assert_css "div.flex.flex-col.primary-color.primary-bg.text-md"

    component = Component.new(theme: :secondary, size: :md, disabled: true)

    render_inline(component)

    assert_css "div.secondary-color.secondary-bg.text-md.opacity-50"
  end

  def test_render_defaults
    component = Component.new(theme: nil, size: nil)

    render_inline(component)

    assert_css "div.flex.flex-col.primary-color.primary-bg.text-sm"
  end

  class SubComponent < Component
    erb_template <<~ERB
      <div class="<%= style(:component, theme: theme, size: size) %>">
        Hello
        <a href="#" class="<%= style(mode: mode) %>">Click</a>
      </div>
    ERB

    style do
      base { "cursor-pointer" }

      variants {
        mode {
          light { %w[text-black] }
          dark { %w[text-white] }
        }
      }
    end

    attr_reader :mode

    def initialize(mode: :light, **parent_opts)
      super(**parent_opts)
      @mode = mode
    end
  end

  def test_inheritance
    component = SubComponent.new(theme: :secondary, size: :lg, mode: :dark)

    render_inline(component)

    assert_css "div.secondary-color.secondary-bg.text-lg"

    assert_css "a.text-white"

    component = SubComponent.new(mode: :light)

    render_inline(component)

    assert_css "a.text-black"
  end

  class SubComponentMerge < Component
    erb_template <<~ERB
      <div class="<%= style(:component, theme: theme, size: size, disabled: disabled) %>">Hello</div>
    ERB
    style :component do
      base { "cursor-pointer" }

      variants(strategy: :merge) {
        size {
          lg { %w[text-larger] }
        }
      }
    end
  end

  def test_inheritance_with_merge_strategy
    # test new lg style
    component = SubComponentMerge.new(theme: :secondary, size: :lg)
    render_inline(component)
    assert_css "div.secondary-color.secondary-bg.text-larger"

    # test inherited md styule
    component = SubComponentMerge.new(theme: :secondary, size: :md)
    render_inline(component)
    assert_css "div.secondary-color.secondary-bg.text-md"
  end

  class SubComponentExtend < Component
    erb_template <<~ERB
      <div class="<%= style(:component, theme: theme, size: size, disabled: disabled) %>">Hello</div>
    ERB
    style :component do
      base { "cursor-pointer" }

      variants(strategy: :extend) {
        size {
          lg { %w[text-larger] }
        }
      }
    end
  end

  def test_inheritance_with_extend_strategy
    # test new lg style
    component = SubComponentExtend.new(theme: :secondary, size: :lg)
    render_inline(component)
    assert_css "div.secondary-color.secondary-bg.text-larger"

    # test does not inherit md styule
    component = SubComponentExtend.new(theme: :secondary, size: :md)
    render_inline(component)
    assert_no_css "div.secondary-color.secondary-bg.text-md"
  end

  class PostProcessedComponent < Component
    style_config.postprocess_with do |compiled|
      compiled.join(" ").gsub("primary", "karamba")
    end

    erb_template <<~ERB
      <div class="<%= style("component", theme: theme, size: size) %>">Hello</div>
    ERB
  end

  def test_postprocessor
    component = PostProcessedComponent.new

    render_inline(component)

    assert_css "div.karamba-color.karamba-bg.text-md"
  end

  class DiffStyleSubcomponent < Component
    erb_template <<~ERB
      <div class="<%= style(:sub, mode: :white, size: :md) %>">Hello</div>
    ERB

    # sibling component name, shouldn't conflict
    style(:sub) do
      variants {
        mode {
          white { %w[text-white] }
          red { %w[text-red] }
        }
        size {
          sm { %w[font-sm] }
          md { %w[font-md] }
          lg { %w[font-lg] }
        }
      }
    end
  end

  def test_style_config_inheritance
    component = SubComponent.new(theme: :secondary, size: :lg, mode: :dark)

    render_inline(component)

    assert_css "a.text-white"

    component = DiffStyleSubcomponent.new

    render_inline(component)

    assert_css "div.text-white.font-md"
  end

  class CompoundComponent < Component
    style do
      variants {
        size {
          sm { %w[text-sm] }
          md { %w[text-md] }
          lg { %w[text-lg] }
        }
        theme {
          primary do |size:, **|
            %w[primary-color primary-bg].tap do
              _1 << "uppercase" if size == :lg
            end
          end

          secondary { %w[secondary-color secondary-bg] }
        }
      }

      compound(size: :sm, theme: :primary) { %w[rounded] }
      compound(size: :md, theme: :secondary) { "underline" }
    end
  end

  def test_dynamic_variants
    component = CompoundComponent.new(theme: :primary, size: :md)

    render_inline(component)

    assert_css "div.primary-color.primary-bg.text-md"

    component = CompoundComponent.new(theme: :primary, size: :lg)

    render_inline(component)

    assert_css "div.primary-color.primary-bg.text-lg.uppercase"

    component = CompoundComponent.new(theme: :primary, size: :sm)

    render_inline(component)

    assert_css "div.primary-color.primary-bg.text-sm.rounded"

    component = CompoundComponent.new(theme: :secondary, size: :md)

    render_inline(component)

    assert_css "div.secondary-color.secondary-bg.text-md.underline"
  end

  class AdditionalClassesComponent < Component
    erb_template <<~ERB
      <div class="<%= style(class: 'bg-blue-500') %>">Hello</div>
    ERB

    style do
    end
  end

  def test_additional_classes
    component = AdditionalClassesComponent.new

    render_inline(component)

    assert_css "div.bg-blue-500"
  end
end
