# frozen_string_literal: true

module ViewComponentContrib
  module TranslationHelper
    DEFAULT_NAMESPACE = "view_components"

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def i18n_namespace=(val)
        @contrib_virtual_path = nil
        @i18n_namespace = val
      end

      def i18n_namespace
        return @i18n_namespace if defined?(@i18n_namespace)

        @i18n_namespace =
          if superclass.respond_to?(:i18n_namespace)
            superclass.i18n_namespace
          else
            DEFAULT_NAMESPACE
          end
      end

      def contrib_i18n_scope
        return @contrib_i18n_scope if defined?(@contrib_i18n_scope)
        # Anonymous classes have no name to derive a scope from
        return [] unless name

        @contrib_i18n_scope = name.sub("::Component", "").underscore.split("/")
      end

      def i18n_scope=(val)
        raise ArgumentError, "Must be array" unless val.is_a?(Array)

        @contrib_virtual_path = nil
        @contrib_i18n_scope = val.dup.freeze
      end

      # ViewComponent (v4.18+) reads the virtual path when a component class is defined,
      # before its body sets i18n_namespace or i18n_scope, so the writers reset it
      def virtual_path
        @contrib_virtual_path ||= [
          i18n_namespace,
          *contrib_i18n_scope
        ].join(".")
      end
    end
  end
end
