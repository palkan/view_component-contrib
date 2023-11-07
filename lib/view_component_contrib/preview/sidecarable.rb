# frozen_string_literal: true

module ViewComponentContrib
  module Preview
    module Sidecarable
      PREVIEW_GLOB = "**/{preview.rb,*_preview.rb}"

      def self.extended(base)
        base.singleton_class.prepend(ClassMethods)
      end

      module ClassMethods
        def load_previews
          Array(preview_paths).each do |preview_path|
            Dir["#{preview_path}/#{PREVIEW_GLOB}"].sort.each { |file| require_dependency file }
          end
        end

        def preview_name
          name.sub(/(::Preview|Preview)$/, "").underscore
        end
      end
    end
  end
end
