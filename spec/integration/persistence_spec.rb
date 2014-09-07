require 'spec_helper'
require 'support/test_classes'
require 'securerandom'

describe 'Persistence' do
  let(:mapper) { Perpetuity[Article] }

  it "persists an object" do
    article = Article.new 'I have a title'
    expect { mapper.insert article }.to change { mapper.count }.by 1
    expect(
      mapper.find(mapper.id_for(article)).title
    ).to eq 'I have a title'
  end

  it 'persists multiple objects' do
    mapper.delete_all
    articles = 2.times.map { Article.new(SecureRandom.hex) }
    expect { mapper.insert articles }.to change { mapper.count }.by 2
    expect(mapper.all.sort(:title).to_a).to be == articles.sort_by(&:title)
  end

  it 'returns the id of the persisted object' do
    article = Article.new
    expect(mapper.insert(article)).to eq mapper.id_for(article)
  end

  it "gives an id to objects" do
    article = Article.new
    mapper.give_id_to article, 1

    expect(mapper.id_for(article)).to eq 1
  end

  it 'persists referenced objects if they are not persisted' do
    article = Article.new
    article.author = User.new
    mapper.insert article

    retrieved = mapper.find(mapper.id_for(article))
    expect(mapper.id_for(retrieved.author)).to be == mapper.id_for(article.author)
  end

  it 'persists arrays of referenced objects if they are not persisted' do
    authors = [User.new('Dave'), User.new('Andy')]
    book = Book.new
    book.authors = authors
    mapper = Perpetuity[Book]
    mapper.insert book

    first_author = mapper.find(mapper.id_for book).authors.first
    expect(mapper.id_for(first_author)).to be == mapper.id_for(authors.first)
  end

  describe 'id injection' do
    let(:article) { Article.new }

    it 'assigns an id to the inserted object' do
      mapper.insert article
      expect(mapper.id_for(article)).not_to be_nil
    end

    it "assigns an id using Mapper.first" do
      expect(mapper.id_for(mapper.first)).not_to be_nil
    end

    it 'assigns an id using Mapper.all.first' do
      expect(mapper.id_for(mapper.all.first)).not_to be_nil
    end
  end

  describe 'persisting arrays' do
    let(:article) { Article.new }

    it 'persists arrays' do
      article.comments << 1 << 2 << 3
      mapper.insert article
      expect(mapper.find(mapper.id_for article).comments).to eq [1, 2, 3]
    end

    it 'persists arrays with unserializable objects in them' do
      comment = Comment.new('my comment')
      article.comments << comment
      mapper.insert article
      persisted_comment = mapper.find(mapper.id_for article).comments.first
      expect(persisted_comment).to be_a Comment
      expect(persisted_comment.body).to eq comment.body
    end
  end

  describe 'persisting hashes' do
    let(:name_hash) { { 'first_name' => 'Jamie', 'last_name' => 'Gaskins' } }
    let(:user) { User.new(name_hash) }
    let(:user_mapper) { Perpetuity[User] }

    it 'saves and retrieves hashes' do
      user_mapper.insert user
      expect(user_mapper.find(user_mapper.id_for user).name).to be == name_hash
    end
  end

  it "allows mappers to set the id field" do
    noise = Time.now.to_f.to_s.sub('.', '')
    book = Book.new("My Title #{noise}")

    Perpetuity[Book].insert book
    expect(Perpetuity[Book].id_for(book)).to eq "my-title-#{noise}"
  end

  context 'with namespaced classes' do
    let(:person) { CRM::Person.new }
    let(:mapper) { Perpetuity[CRM::Person] }

    before { person.name = 'Foo Bar' }

    it 'persists even with colons in the names' do
      mapper.insert person
      expect(mapper.persisted?(person)).to be_truthy
    end
  end
end

