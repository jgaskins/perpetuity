class Article
  attr_accessor :title, :body, :author, :comments, :published_at, :views
  def initialize title="Title", body="Body", author=nil, published_at=Time.now, views=0
    @title = title
    @body = body
    @author = author
    @comments = []
    @published_at = published_at
    @views = views
  end

  def == other
    title == other.title &&
    body == other.body
  end
end
