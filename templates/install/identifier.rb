

  private

  def identifier
    @identifier ||= self.class.name.sub("::Component", "").underscore.split("/").join("--")
  end