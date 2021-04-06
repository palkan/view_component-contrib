# frozen_string_literal: true

module ViewComponentContrib
  module Preview
    module DefaultTemplate
      DEFAULT_TEMPLATE = "view_component_contrib/preview"

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

        def preview_example_template_path(*)
          super
        rescue ViewComponent::PreviewTemplateError
          has_preview_template = preview_paths.find do |path|
            Dir.glob(File.join(path, preview_name, "preview.html.*")).any?
          end

          has_preview_template ? File.join(preview_name, "preview") : DEFAULT_TEMPLATE
        end
      end
    end
  end
end

ActiveSupport.on_load(:view_component) do
  ViewComponent::Base.preview_paths << File.expand_path(File.join(__dir__, "../../../app/views"))
end
