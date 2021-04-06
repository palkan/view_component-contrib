# frozen_string_literal: true

class Banner::Component < ViewComponentContrib::Base
  attr_reader :text

  def initialize(text: "Welcome!")
    @text = text
  end

  def call
    "<div>#{text}</div>".html_safe
  end
end
