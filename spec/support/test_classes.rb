%w( user article comment book message topic car ).each do |file|
  require "support/test_classes/#{file}"
end

Perpetuity.generate_mapper_for User do
  attribute :name
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
    select { |article| (article.published_at.not_equal? nil) &
                       (article.published_at < Time.now) }
  end

  def unpublished
    select { |article| (article.published_at == nil) |
                       (article.published_at > Time.now) }
  end
end

Perpetuity.generate_mapper_for(Comment) do
  attribute :body
  attribute :author
end

Perpetuity.generate_mapper_for Book do
  id { title.gsub(/\W+/, '-').downcase }
  attribute :title
  attribute :authors
end

Perpetuity.generate_mapper_for Message do
  attribute :text
end

Perpetuity.generate_mapper_for(Topic) do
  attribute :title
  attribute :creator
end

Perpetuity.generate_mapper_for(Car) do
  attribute :make
  attribute :model
  attribute :seats

  validate do
    present :make
  end
end
