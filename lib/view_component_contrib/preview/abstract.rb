# frozen_string_literal: true

module ViewComponentContrib
  module Preview
    # Adds `abstract_class` accessor and exclude abstract
    # preview classes from index
    module Abstract
      def self.extended(base)
        base.singleton_class.prepend(ClassMethods)
      end

      module ClassMethods
        attr_accessor :abstract_class
        alias_method :abstract_class?, :abstract_class

        def all
          load_previews if descendants.reject(&:abstract_class?).empty?
          descendants.reject(&:abstract_class?)
        end
      end
    end
  end
end
