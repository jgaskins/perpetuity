class Message
  def initialize text="My Message!"
    self.text = text
  end

  def text
    @text.reverse
  end

  def text= new_text
    @text = new_text.reverse
  end
end
