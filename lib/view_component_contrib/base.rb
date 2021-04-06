# frozen_string_literal: true

module ViewComponentContrib
  # Base view component class with many extensions already included
  class Base < ViewComponent::Base
    include TranslationHelper
  end
end
