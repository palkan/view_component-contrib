# frozen_string_literal: true

module ViewComponentContrib
  module Preview
    module DefaultTemplate
      DEFAULT_TEMPLATE = "view_component_contrib/preview"

      # Make sure view components errors are loaded
      begin
        require "view_component/errors"
      rescue LoadError
      end

      MISSING_TEMPLATE_ERROR = if ViewComponent.const_defined?(:MissingPreviewTemplateError)
        ViewComponent::MissingPreviewTemplateError
      else
        ViewComponent::PreviewTemplateError
      end

      def self.included(base)
        base.singleton_class.prepend(ClassMethods)
      end

      module ClassMethods
        attr_writer :default_preview_template

        def default_preview_template
          return @default_preview_template if defined?(@default_preview_template)

          @default_preview_template =
            if superclass.respond_to?(:default_preview_template)
              superclass.default_preview_template
            else
              DEFAULT_TEMPLATE
            end
        end

        def preview_example_template_path(example)
          super
        rescue MISSING_TEMPLATE_ERROR
          has_example_preview = preview_paths.find do |path|
            Dir.glob(File.join(path, preview_name, "previews", "#{example}.html.*")).any?
          end

          return File.join(preview_name, "previews", example) if has_example_preview

          has_root_preview = preview_paths.find do |path|
            Dir.glob(File.join(path, preview_name, "preview.html.*")).any?
          end

          return File.join(preview_name, "preview") if has_root_preview

          default_preview_template
        end
      end
    end
  end
end
