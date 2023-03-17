# frozen_string_literal: true

require "test_helper"

return unless defined?(::RubyBytes)

class TemplateTest < Minitest::Test
  def test_template_compiles
    assert RubyBytes::Compiler.new(File.join(__dir__, "../../templates/install/template.rb")).render
  end
end
