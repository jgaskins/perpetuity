require 'spec_helper'
require 'support/test_classes'

describe Perpetuity do
  describe 'mapper generation' do
    it 'generates mappers' do
      Perpetuity.generate_mapper_for Object
      Perpetuity[Object].should be_a Perpetuity::Mapper
    end

    it 'provides a DSL within the generated mapper' do
      Perpetuity.generate_mapper_for Object do
        id { object_id + 1 }
        attribute :object_id
      end

      mapper = Perpetuity[Object]
      object = Object.new
      mapper.insert object
      object.id.should eq object.object_id + 1
      mapper.attributes.should eq [:object_id]
    end
  end

  describe 'serialization' do
    let(:author) { User.new 'username' }
    let(:comment) { Comment.new }
    let(:article) { Article.new }
    let(:mapper) { Perpetuity[Article] }
    let(:serialized_value) do
      {
        'title' => article.title,
        'body' => article.body,
        'author' => {
          '__metadata__' => {
            'class' => author.class.to_s,
            'id' => author.id
          }
        },
        'comments' => [
          {
            '__metadata__' => {
              'class' => comment.class.to_s
            },
            'body' => comment.body,
            'author' => {
              '__metadata__' => {
                'class' => author.class.to_s,
                'id' => author.id
              }
            }
          },
        ],
        'published_at' => article.published_at,
        'views' => article.views
      } 
    end

    before do
      article.author = author
      article.comments = [comment]
      comment.author = author

      Perpetuity[User].insert author
      Perpetuity[Article].insert article
    end

    it 'serializes objects into hashes' do
      mapper.serialize(article).should be == serialized_value
    end

    it 'deserializes hashes into proper objects' do
      unserialized = mapper.find article.id
      unserialized.should be_a Article
      unserialized.title.should be == article.title
      unserialized.body.should be == article.body
      unserialized.comments.first.tap do |unserialized_comment|
        unserialized_comment.body.should be == comment.body
      end
    end
  end

  describe 'methods on mappers' do
    it 'allows methods to act as scopes' do
      published = Article.new('Published', 'I love cats', nil, Time.now - 30)
      draft = Article.new('Draft', 'I do not like moose', nil, nil)
      not_yet_published = Article.new('Tomorrow', 'Dogs', nil, Time.now + 30)

      mapper = Perpetuity[Article]
      mapper.insert published
      mapper.insert draft
      mapper.insert not_yet_published

      published_ids = mapper.published.to_a.map(&:id)
      published_ids.should include published.id
      published_ids.should_not include draft.id, not_yet_published.id

      unpublished_ids = mapper.unpublished.to_a.map(&:id)
      unpublished_ids.should_not include published.id
      unpublished_ids.should include draft.id, not_yet_published.id
    end
  end

  describe 'indexing' do
    let(:mapper_class) do
      Class.new(Perpetuity::Mapper) do
        map Object
        attribute :name
        index :name, unique: true
      end
    end
    let(:mapper) { mapper_class.new }
    let(:name_index) do
      mapper.indexes.find do |index|
        index.attribute.to_s == :name
      end
    end

    after { mapper.data_source.drop_collection Object }

    it 'adds indexes to database collections/tables' do
      name_index.attribute.name.should be == :name
    end

    it 'verifies that indexes are inactive' do
      name_index.should be_inactive
    end

    it 'creates indexes' do
      mapper.reindex!
      name_index.should be_active
      mapper.remove_index! name_index
    end

    it 'specifies uniqueness of the index' do
      name_index.should be_unique
    end
  end
end
