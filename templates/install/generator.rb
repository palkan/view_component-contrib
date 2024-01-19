if yes?("Would you like to create a custom generator for your setup? (y/n)")
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
    class_option :skip_system_test, type: :boolean, default: false
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

    def create_system_test_file
      return if options[:skip_system_test]

      template "component_system_#{TEST_SUFFIX}.rb", File.join("#{TEST_SYSTEM_ROOT_PATH}", class_path, "\#{file_name}_#{TEST_SUFFIX}.rb")
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
          with_collection_parameter :<%%= singular_name %>
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
          with_collection_parameter :<%%= singular_name %>
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
    file "lib/generators/view_component/templates/component.html.haml.tt", <<~CODE
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

    file "lib/generators/view_component/templates/component_system_spec.rb.tt", <<~CODE
    # frozen_string_literal: true

    require "rails_helper"

    describe "<%%= file_name %> component" do
      it "default preview" do
        visit("/rails/view_components<%%= File.join(class_path, file_name) %>/default")

        # is_expected.to have_text "Hello!"
        # click_on "Click me"
        # is_expected.to have_text "Good-bye!"
      end
    end
      CODE
  else
    file "lib/generators/view_component/templates/component_test.rb.tt", <<~CODE
  # frozen_string_literal: true

  require "test_helper"

  class <%%= class_name %>::ComponentTest < ViewComponent::TestCase
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

    file "lib/generators/view_component/templates/component_system_test.rb.tt", <<~CODE
  # frozen_string_literal: true

  require "application_system_test_case"

  class <%%= class_name %>::ComponentSystemTest < ApplicationSystemTestCase
    def test_default_preview
      visit("/rails/view_components<%%= File.join(class_path, file_name) %>/default")

      # assert_text "Hello!"
      # click_on("Click me!")
      # assert_text "Good-bye!"
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
          System Test:  #{TEST_SYSTEM_ROOT_PATH}/profile_component_#{TEST_SUFFIX}.rb
          Preview:      #{ROOT_PATH}/profile/component_preview.rb
  CODE

  # Check if autoload_lib is configured
  if File.file?("config/application.rb") && File.read("config/application.rb").include?("config.autoload_lib")
    say_status :info, "⚠️  Make sure you configured autoload_lib to ignore the lib/generators folder"
  end
end
