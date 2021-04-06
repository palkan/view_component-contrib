# frozen_string_literal: true

class CustomBanner::Component < ViewComponentContrib::Base
  attr_reader :text

  def initialize(text:)
    @text = text
  end

  def call
    "<div>#{text}</div>".html_safe
  end
end
