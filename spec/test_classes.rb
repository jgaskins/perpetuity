class User
  attr_accessor :name
  def initialize name="Foo"
    @name = name
  end
end

Perpetuity.generate_mapper_for User do
  attribute :name
end

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
end

class ArticleMapper < Perpetuity::Mapper
  map Article
  attribute :title
  attribute :body
  attribute :author
  attribute :comments
  attribute :published_at
  attribute :views

  def published
    select { (published_at.not_equal? nil) & (published_at < Time.now) }
  end

  def unpublished
    select { (published_at == nil) | (published_at > Time.now) }
  end
end

class Comment
  attr_accessor :body, :author
  def initialize body='Body', author=nil
    @body = body
    @author = author
  end
end

Perpetuity.generate_mapper_for(Comment) do
  attribute :body
  attribute :author
end

class Book
  attr_accessor :title
  def initialize title="Foo Bar"
    @title = title
  end
end

Perpetuity.generate_mapper_for Book do
  id { title.gsub(/\W+/, '-').downcase }
  attribute :title
end

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

Perpetuity.generate_mapper_for Message do
  attribute :text
end

class Topic
  attr_accessor :title, :creator
end

Perpetuity.generate_mapper_for(Topic) do
  attribute :title
  attribute :creator
end

class Car
  attr_accessor :make, :model, :seats
end

Perpetuity.generate_mapper_for(Car) do
  attribute :make
  attribute :model
  attribute :seats

  validate do
    present :make
  end
end
