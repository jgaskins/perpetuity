require 'spec_helper'
require 'support/test_classes'

describe 'updating' do
  let(:article) { Article.new }
  let(:mapper) { Perpetuity[Article] }
  let(:new_title) { 'I has a new title!' }

  before do
    mapper.insert article
  end

  it 'updates an object in the database' do
    mapper.update article, title: new_title
    mapper.find(article.id).title.should eq new_title
  end

  it 'updates the object in memory' do
    mapper.update article, title: new_title
    article.title.should eq new_title
  end

  it 'resaves the object in the database' do
    article.title = new_title
    mapper.save article
    mapper.find(article.id).title.should eq new_title
  end

  it 'updates an object with referenced attributes' do
    user = User.new
    article.author = user
    mapper.save article

    retrieved_article = mapper.find(article.id)
    retrieved_article.title = new_title
    mapper.save retrieved_article

    retrieved_article = mapper.find(retrieved_article.id)
    retrieved_article.author.should be_a Perpetuity::Reference
  end

  it 'updates an object with an array of referenced attributes' do
    dave = User.new('Dave')
    andy = User.new('Andy')
    authors = [dave]
    book = Book.new("Title #{Time.now.to_f}", authors)
    mapper = Perpetuity[Book]

    mapper.insert book

    retrieved_book = mapper.find(book.id, false)
    retrieved_book.authors << andy
    mapper.save retrieved_book

    retrieved_authors = mapper.find(retrieved_book.id).authors
    retrieved_authors.map(&:klass).should == [User, User]
    retrieved_authors.map(&:id).should == [dave.id, andy.id]
  end

  describe 'atomic increments/decrements' do
    let(:view_count) { 0 }
    let(:article) { Article.new('title', 'body', nil, nil, view_count) }

    it 'increments attributes of objects in the database' do
      mapper.increment article, :views
      mapper.increment article, :views, 10
      mapper.find(article.id).views.should == view_count + 11
    end

    it 'decrements attributes of objects in the database' do
      mapper.decrement article, :views
      mapper.decrement article, :views, 10
      mapper.find(article.id).views.should == view_count - 11
    end

    context 'with an object with the specified attribute missing' do
      let(:article) { Article.new('title', 'body', nil, nil, nil) }

      it 'raises an exception when incrementing' do
        expect { mapper.increment article, :views }.to raise_error(
          ArgumentError, 'Attempted to increment a non-numeric value')
      end

      it 'raises an exception when decrementing' do
        expect { mapper.decrement article, :views }.to raise_error(
          ArgumentError, 'Attempted to decrement a non-numeric value')
      end
    end
  end
end


