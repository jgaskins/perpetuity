class Comment
  attr_accessor :body, :author
  def initialize body='Body', author=nil
    @body = body
    @author = author
  end
end
