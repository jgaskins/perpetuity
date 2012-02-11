class Article
  attr_reader :title, :body
  def initialize title="Title", body="Body", author=nil
    @title = title
    @body = body
  end
end

class ArticleMapper < Perpetuity::Mapper
  attribute :title, String
  attribute :body, String
end

class User
  attr_accessor :name
  def initialize name="Foo"
    @name = name
  end
end

class UserMapper < Perpetuity::Mapper
  attribute :name, String
end
