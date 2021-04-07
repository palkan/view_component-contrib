# frozen_string_literal: true

class TemplateBuilder
  attr_reader :root

  def initialize(root)
    @root = root
  end

  def get_binding
    binding
  end

  def embed_code(path)
    contents = File.read(File.join(root, path))
    %Q(<<-CODE
#{contents}
CODE)
  end

  def embed(path)
    File.read(File.join(root, path))
  end
end
