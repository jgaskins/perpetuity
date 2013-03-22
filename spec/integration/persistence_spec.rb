require 'spec_helper'
require 'support/test_classes'

describe 'Persistence' do
  it "persists an object" do
    article = Article.new 'I have a title'
    expect { Perpetuity[Article].insert article }.
      to change { Perpetuity[Article].count }.by 1
    Perpetuity[Article].find(article.id).title.should eq 'I have a title'
  end

  it 'returns the id of the persisted object' do
    article = Article.new
    Perpetuity[Article].insert(article).should eq article.id
  end

  it "gives an id to objects" do
    article = Article.new
    Perpetuity[Article].give_id_to article, 1

    article.id.should eq 1
  end

  it 'persists referenced objects if they are not persisted' do
    article = Article.new
    article.author = User.new
    Perpetuity[Article].insert article

    Perpetuity[Article].find(article.id).author.id.should be == article.author.id
  end

  it 'persists arrays of referenced objects if they are not persisted' do
    authors = [User.new('Dave'), User.new('Andy')]
    book = Book.new
    book.authors = authors
    Perpetuity[Book].insert book

    Perpetuity[Book].find(book.id).authors.first.id.should be == authors.first.id
  end

  describe 'id injection' do
    let(:article) { Article.new }

    it 'assigns an id to the inserted object' do
      Perpetuity[Article].insert article
      article.should respond_to :id
    end

    it "assigns an id using Mapper.first" do
      Perpetuity[Article].first.should respond_to :id
    end

    it 'assigns an id using Mapper.all.first' do
      Perpetuity[Article].all.first.should respond_to :id
    end
  end

  describe 'persisting arrays' do
    let(:article) { Article.new }

    it 'persists arrays' do
      article.comments << 1 << 2 << 3
      Perpetuity[Article].insert article
      Perpetuity[Article].find(article.id).comments.should eq [1, 2, 3]
    end

    it 'persists arrays with unserializable objects in them' do
      comment = Comment.new('my comment')
      article.comments << comment
      Perpetuity[Article].insert article
      Perpetuity[Article].find(article.id).comments.first.tap do |persisted_comment|
        persisted_comment.should be_a Comment
        persisted_comment.body.should eq comment.body
      end
    end
  end

  describe 'persisting hashes' do
    let(:name_hash) { { 'first_name' => 'Jamie', 'last_name' => 'Gaskins' } }
    let(:user) { User.new(name_hash) }
    let(:user_mapper) { Perpetuity[User] }

    it 'saves and retrieves hashes' do
      user_mapper.insert user
      user_mapper.find(user.id).name.should be == name_hash
    end
  end

  it "allows mappers to set the id field" do
    noise = Time.now.to_f.to_s.sub('.', '')
    book = Book.new("My Title #{noise}")

    Perpetuity[Book].insert book
    book.id.should eq "my-title-#{noise}"
  end

  context 'with namespaced classes' do
    let(:person) { CRM::Person.new }
    let(:mapper) { Perpetuity[CRM::Person] }

    before { person.name = 'Foo Bar' }

    it 'persists even with colons in the names' do
      mapper.insert person
      person.should be_a Perpetuity::PersistedObject
    end
  end
end

