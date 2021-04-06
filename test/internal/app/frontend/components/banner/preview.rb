# frozen_string_literal: true

class Banner::Preview < ApplicationViewComponentPreview
  def default
  end

  def alert
    render_component Banner::Component.new(text: "Alarma!")
  end

  def wide
    render_with(
      component: Banner::Component.new(text: "Wide"),
      container_class: "w-full"
    )
  end
end
