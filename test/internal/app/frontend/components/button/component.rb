# frozen_string_literal: true

class Button::Component < ViewComponentContrib::Base
  attr_reader :type, :kind

  def initialize(type: "button", kind: "primary")
    @type = type
    @kind = kind
  end
end
