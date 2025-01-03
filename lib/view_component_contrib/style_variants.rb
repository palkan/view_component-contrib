# frozen_string_literal: true

module ViewComponentContrib
  # Organize style in variants that can be combined.
  # Inspired by https://www.tailwind-variants.org and https://cva.style/docs/getting-started/variants
  #
  # Example:
  #
  #   class ButtonComponent < ViewComponent::Base
  #     include ViewComponentContrib::StyleVariants
  #
  #     erb_template <<~ERB
  #       <button class="<%= style(size: 'sm', color: 'secondary') %>">Click me</button>
  #     ERB
  #
  #     style do
  #       base {
  #         %w(
  #           font-medium bg-blue-500 text-white rounded-full
  #         )
  #       }
  #       variants {
  #         color {
  #           primary { %w(bg-blue-500 text-white) }
  #           secondary  { %w(bg-purple-500 text-white) }
  #         }
  #         size {
  #           sm { "text-sm" }
  #           md { "text-base" }
  #           lg { "px-4 py-3 text-lg" }
  #         }
  #       }
  #       defaults { {size: :md, color: :primary} }
  #    end
  #
  #    attr_reader :size, :color
  #
  #    def initialize(size: :md, color: :primary)
  #      @size = size
  #      @color = color
  #    end
  #  end
  #
  module StyleVariants
    class VariantBuilder
      attr_reader :unwrap_blocks

      def initialize(unwrap_blocks = true)
        @unwrap_blocks = unwrap_blocks
        @variants = {}
      end

      def build(&block)
        instance_eval(&block)
        @variants
      end

      def respond_to_missing?(name, include_private = false)
        true
      end

      def method_missing(name, &block)
        return super unless block_given?

        @variants[name] = if unwrap_blocks
          VariantBuilder.new(false).build(&block)
        else
          block
        end
      end
    end

    class StyleSet
      def initialize(&init_block)
        @base_block = nil
        @defaults = {}
        @variants = {}
        @compounds = {}

        return unless init_block

        @init_block = init_block
        instance_eval(&init_block)
      end

      def base(&block)
        @base_block = block
      end

      def defaults(&block)
        @defaults = block.call.freeze
      end

      def variants(strategy: :override, &block)
        variants = build_variants(&block)
        @variants = handle_variants(variants, strategy)
      end

      def build_variants(&block)
        VariantBuilder.new(true).build(&block)
      end

      def handle_variants(variants, strategy)
        return variants if strategy == :override

        parent_variants = find_parent_variants
        return variants unless parent_variants

        return parent_variants.deep_merge(variants) if strategy == :merge

        parent_variants.merge(variants) if strategy == :extend
      end

      def find_parent_variants
        parent_component = @init_block.binding.receiver.superclass
        return unless parent_component.respond_to?(:style_config)

        parent_config = parent_component.style_config
        default_parent_style = parent_component.default_style_name
        parent_style_set = parent_config.instance_variable_get(:@styles)[default_parent_style.to_sym]
        parent_style_set.instance_variable_get(:@variants).deep_dup
      end

      def compound(**variants, &block)
        @compounds[variants] = block
      end

      def compile(**variants)
        acc = Array(@base_block&.call || [])

        config = @defaults.merge(variants.compact)

        config.each do |variant, value|
          value = cast_value(value)
          variant = @variants.dig(variant, value) || next
          styles = variant.is_a?(::Proc) ? variant.call(**config) : variant
          acc.concat(Array(styles))
        end

        @compounds.each do |compound, value|
          next unless compound.all? { |k, v| config[k] == v }

          styles = value.is_a?(::Proc) ? value.call(**config) : value
          acc.concat(Array(styles))
        end

        acc.concat(Array(config[:class]))
        acc.concat(Array(config[:class_name]))
        acc
      end

      def dup
        copy = super
        copy.instance_variable_set(:@defaults, @defaults.dup)
        copy.instance_variable_set(:@variants, @variants.dup)
        copy.instance_variable_set(:@compounds, @compounds.dup)
        copy
      end

      private

      def cast_value(val)
        case val
        when true then :yes
        when false then :no
        else
          val
        end
      end
    end

    class StyleConfig # :nodoc:
      DEFAULT_POST_PROCESSOR = ->(compiled) { compiled.join(" ") }

      attr_reader :postprocessor

      def initialize
        @styles = {}
        @postprocessor = DEFAULT_POST_PROCESSOR
      end

      def define(name, &block)
        styles[name] = StyleSet.new(&block)
      end

      def compile(name, **variants)
        styles[name]&.compile(**variants).then do |compiled|
          next unless compiled

          postprocess(compiled)
        end
      end

      # Allow defining a custom postprocessor
      def postprocess_with(callable = nil, &block)
        @postprocessor = callable || block
      end

      def dup
        copy = super
        copy.instance_variable_set(:@styles, @styles.dup)
        copy
      end

      private

      attr_reader :styles

      def postprocess(compiled) = postprocessor.call(compiled)
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Returns the name of the default style set based on the class name:
      #  MyComponent::Component => my_component
      #  Namespaced::MyComponent => my_component
      def default_style_name
        @default_style_name ||= name.demodulize.sub(/(::Component|Component)$/, "").underscore.presence || "component"
      end

      def style(name = default_style_name, &block)
        style_config.define(name.to_sym, &block)
      end

      def style_config
        @style_config ||=
          if superclass.respond_to?(:style_config)
            superclass.style_config.dup
          else
            StyleConfig.new
          end
      end
    end

    def style(name = self.class.default_style_name, **variants)
      self.class.style_config.compile(name.to_sym, **variants)
    end
  end
end
