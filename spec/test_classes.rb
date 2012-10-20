class Article
  attr_accessor :title, :body, :comments, :published_at, :views
  def initialize title="Title", body="Body", author=nil, published_at=Time.now, views=0
    @title = title
    @body = body
    @comments = []
    @published_at = published_at
    @views = views
  end
end

Perpetuity.generate_mapper_for(Article) do
  attribute :title, String
  attribute :body, String
  attribute :comments, Array, embedded: true
  attribute :published_at, Time
  attribute :views, Integer
end

class Comment
  attr_reader :body
  def initialize body='Body'
    @body = body
  end
end

Perpetuity.generate_mapper_for(Comment) do
  attribute :body, String
end

class User
  attr_accessor :name
  def initialize name="Foo"
    @name = name
  end
end

Perpetuity.generate_mapper_for User do
  attribute :name, String
end

class Book
  attr_accessor :title
  def initialize title="Foo Bar"
    @title = title
  end
end

Perpetuity.generate_mapper_for Book do
  id { title.gsub(/\W+/, '-').downcase }
  attribute :title, String
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
  attribute :text, String
end

class Topic
  attr_accessor :title, :creator
end

Perpetuity.generate_mapper_for(Topic) do
  attribute :title, String
  attribute :creator, User
end

class Car
  attr_accessor :make, :model, :seats
end

Perpetuity.generate_mapper_for(Car) do
  attribute :make, String
  attribute :model, String
  attribute :seats, Integer

  validate do
    present :make
  end
end
