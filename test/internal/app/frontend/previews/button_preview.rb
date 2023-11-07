# frozen_string_literal: true

class ButtonPreview < ApplicationViewComponentPreview
  def info
    render_component(kind: :info) { "Info" }
  end

  def danger
    render_component(kind: :danger) { "Danger" }
  end
end
