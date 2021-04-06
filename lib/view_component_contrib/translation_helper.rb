# frozen_string_literal: true

module ViewComponentContrib
  module TranslationHelper
    DEFAULT_NAMESPACE = "view_components"

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_writer :i18n_namespace

      def i18n_namespace
        return @i18n_namespace if defined?(@i18n_namespace)

        @i18n_namespace =
          if superclass.respond_to?(:i18n_namespace)
            superclass.i18n_namespace
          else
            DEFAULT_NAMESPACE
          end
      end

      def i18n_scope
        return @i18n_scope if defined?(@i18n_scope)

        @i18n_scope = name.sub("::Component", "").underscore.split("/")
      end

      def i18n_scope=(val)
        raise ArgumentError, "Must be array" unless val.is_a?(Array)

        @i18n_scope = val.dup.freeze
      end

      def virtual_path
        @contrib_virtual_path ||= [
          i18n_namespace,
          *i18n_scope
        ].join(".")
      end
    end
  end
end
