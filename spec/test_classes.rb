class Article
  attr_reader :title, :body
  def initialize title="Title", body="Body"
    @title = title
    @body = body
  end
end