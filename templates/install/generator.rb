if yes?("Would you like to create a custom generator for your setup? (Recommended)")
  template_choice_to_ext = {"1" => ".erb", "2" => ".haml", "3" => ".slim"}

  template = ask "Which template processor do you use? (1) ERB, (2) Haml, (3) Slim, (0) Other"

  TEMPLATE_EXT = template_choice_to_ext.fetch(template, "")
  TEST_SUFFIX = USE_RSPEC ? 'spec' : 'test'

  file "lib/generators/view_component/view_component_generator.rb", <<~CODE
  # frozen_string_literal: true

  # Based on https://github.com/github/view_component/blob/master/lib/rails/generators/component/component_generator.rb
  class ViewComponentGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    class_option :skip_test, type: :boolean, default: false
    class_option :skip_preview, type: :boolean, default: false

    argument :attributes, type: :array, default: [], banner: "attribute"

    def create_component_file
      template "component.rb", File.join("#{ROOT_PATH}", class_path, file_name, "component.rb")
    end

    def create_template_file
      template "component.html#{TEMPLATE_EXT}", File.join("#{ROOT_PATH}", class_path, file_name, "component.html#{TEMPLATE_EXT}")
    end

    def create_test_file
      return if options[:skip_test]

      template "component_#{TEST_SUFFIX}.rb", File.join("#{TEST_ROOT_PATH}", class_path, "\#{file_name}_#{TEST_SUFFIX}.rb")
    end

    def create_preview_file
      return if options[:skip_preview]

      template "preview.rb", File.join("#{ROOT_PATH}", class_path, file_name, "preview.rb")
    end

    private

    def parent_class
      "ApplicationViewComponent"
    end

    def preview_parent_class
      "ApplicationViewComponentPreview"
    end
  end
  CODE

  if USE_WEBPACK
    inject_into_file "lib/generators/view_component/view_component_generator.rb", after: "class_option :skip_preview, type: :boolean, default: false\n" do
      <<-CODE
  class_option :skip_js, type: :boolean, default: false
  class_option :skip_css, type: :boolean, default: false
      CODE
    end

    inject_into_file "lib/generators/view_component/view_component_generator.rb", before: "\n  private" do
      <<-CODE
  def create_css_file
    return if options[:skip_css] || options[:skip_js]

    template "index.css", File.join("#{ROOT_PATH}", class_path, file_name, "index.css")
  end

  def create_js_file
    return if options[:skip_js]

    template "index.js", File.join("#{ROOT_PATH}", class_path, file_name, "index.js")
  end
      CODE
    end
  end

  if USE_DRY
    inject_into_file "lib/generators/view_component/view_component_generator.rb", before: "\nend" do
      <<-CODE


  def initialize_signature
    return if attributes.blank?

    attributes.map { |attr| "option :\#{attr.name}" }.join("\\n  ")
  end
      CODE
    end

    file "lib/generators/view_component/templates/component.rb.tt",
      <<~CODE
        # frozen_string_literal: true

        class <%%= class_name %>::Component < <%%= parent_class %>
        <%%- if initialize_signature -%>
          <%%= initialize_signature %>
        <%%- end -%>
        end
      CODE
  else
    inject_into_file "lib/generators/view_component/view_component_generator.rb", before: "\nend" do
      <<-CODE


  def initialize_signature
    return if attributes.blank?

    attributes.map { |attr| "\#{attr.name}:" }.join(", ")
  end

  def initialize_body
    attributes.map { |attr| "@\#{attr.name} = \#{attr.name}" }.join("\\n    ")
  end
      CODE
    end

    file "lib/generators/view_component/templates/component.rb.tt",
      <<~CODE
        # frozen_string_literal: true

        class <%%= class_name %>::Component < <%%= parent_class %>
        <%%- if initialize_signature -%>
          def initialize(<%%= initialize_signature %>)
            <%%= initialize_body %>
          end
        <%%- end -%>
        end
      CODE
  end

  if TEMPLATE_EXT == ".slim"
    file "lib/generators/view_component/templates/component.html.slim.tt", <<~CODE
    div Add <%%= class_name %> template here
    CODE
  end

  if TEMPLATE_EXT == ".erb"
    file "lib/generators/view_component/templates/component.html.erb.tt", <<~CODE
    <div>Add <%%= class_name %> template here</div>
    CODE
  end

  if TEMPLATE_EXT == ".haml"
    file "lib/generators/view_component/templates/component.html.tt", <<~CODE
    %div Add <%%= class_name %> template here
    CODE
  end

  if TEMPLATE_EXT == ""
    file "lib/generators/view_component/templates/component.html.tt", <<~CODE
    <div>Add <%%= class_name %> template here</div>
    CODE
  end

  file "lib/generators/view_component/templates/preview.rb.tt", <<~CODE
  # frozen_string_literal: true

  class <%%= class_name %>::Preview < <%%= preview_parent_class %>
    # You can specify the container class for the default template
    # self.container_class = "w-1/2 border border-gray-300"

    def default
    end
  end
  CODE

  if USE_WEBPACK
    if USE_STIMULUS
      file "lib/generators/view_component/templates/index.js.tt",
      <<-CODE
import "./index.css"

// Add a Stimulus controller for this component.
// It will automatically registered and its name will be available
// via #component_name in the component class.
//
// import { Controller as BaseController } from "stimulus";
//
// export class Controller extends BaseController {
//   connect() {
//   }
//
//   disconnect() {
//   }
// }
      CODE
    else
      file "lib/generators/view_component/templates/index.js.tt", <<~CODE
      import "./index.css"

      CODE
    end

    if USE_POSTCSS_MODULES
      file "lib/generators/view_component/templates/index.css.tt", <<~CODE
      /* Use component-local class names and add them to HTML via #class_for(name) helper */

      CODE
    else
      file "lib/generators/view_component/templates/index.css.tt", ""
    end
  end

  if USE_RSPEC
    file "lib/generators/view_component/templates/component_spec.rb.tt", <<~CODE
  # frozen_string_literal: true

  require "rails_helper"

  describe <%%= class_name %>::Component do
    let(:options) { {} }
    let(:component) { <%%= class_name %>::Component.new(**options) }

    subject { rendered_content }

    it "renders" do
      render_inline(component)

      is_expected.to have_css "div"
    end
  end
    CODE
  else
    file "lib/generators/view_component/templates/component_test.rb.tt", <<~CODE
  # frozen_string_literal: true

  require "test_helper"

  class <%%= class_name %>::ComponentTest < ActiveSupport::TestCase
    include ViewComponent::TestHelpers

    def test_renders
      component = build_component

      render_inline(component)

      assert_selector "div"
    end

    private

    def build_component(**options)
      <%%= class_name %>::Component.new(**options)
    end
  end
    CODE
  end

  file "lib/generators/view_component/USAGE", <<~CODE
  Description:
  ============
      Creates a new view component, test and preview files.
      Pass the component name, either CamelCased or under_scored, and an optional list of attributes as arguments.

  Example:
  ========
      bin/rails generate view_component Profile name age

      creates a Profile component and test:
          Component:    #{ROOT_PATH}/profile/component.rb
          Template:     #{ROOT_PATH}/profile/component.html#{TEMPLATE_EXT}
          Test:         #{TEST_ROOT_PATH}/profile_component_#{TEST_SUFFIX}.rb
          Preview:      #{ROOT_PATH}/profile/component_preview.rb
  CODE

  if USE_WEBPACK
    inject_into_file "lib/generators/view_component/USAGE" do
      <<-CODE
          JS:           #{ROOT_PATH}/profile/component.js
          CSS:          #{ROOT_PATH}/profile/component.css
      CODE
    end
  end
end
