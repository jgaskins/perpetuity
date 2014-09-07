require 'spec_helper'
require 'support/test_classes'

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
          'id' => mapper.id_for(author)
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
              'id' => mapper.id_for(author)
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
    expect(mapper.serialize(article)).to be == serialized_value
  end

  it 'deserializes hashes into proper objects' do
    unserialized = mapper.find mapper.id_for(article)
    expect(unserialized).to be_a Article
    expect(unserialized.title).to be == article.title
    expect(unserialized.body).to be == article.body
    unserialized.comments.first.tap do |unserialized_comment|
      expect(unserialized_comment.body).to be == comment.body
    end
  end
end
