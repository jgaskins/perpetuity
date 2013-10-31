%w( user article comment book message topic car crm_person generic_object).each do |file|
  require "support/test_classes/#{file}"
end

class UserMapper < Perpetuity::Mapper
  map User
  attribute :name, type: String
end

Perpetuity.generate_mapper_for Article do
  attribute :title, type: String
  attribute :body, type: String
  attribute :author, type: User
  attribute :comments, type: Array, embedded: true
  attribute :published_at, type: Time
  attribute :views, type: Integer

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
  attribute :body, type: String
  attribute :author, type: User
end

Perpetuity.generate_mapper_for Book do
  id(String) { title.gsub(/\W+/, '-').downcase }
  attribute :title, type: String
  attribute :authors, type: Array
end

Perpetuity.generate_mapper_for Message do
  attribute :text, type: String
end

Perpetuity.generate_mapper_for(Topic) do
  attribute :title, type: String
  attribute :creator, type: User
end

Perpetuity.generate_mapper_for(Car) do
  attribute :make, type: String
  attribute :model, type: String
  attribute :seats, type: Integer
end

Perpetuity.generate_mapper_for CRM::Person do
  attribute :name, type: String
end

Perpetuity.generate_mapper_for GenericObject do
  attribute :referenced_attribute, type: Object
  attribute :embedded_attribute, type: Object, embedded: true
end
