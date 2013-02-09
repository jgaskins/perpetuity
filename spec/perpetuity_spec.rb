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

  describe 'pagination' do
    it 'specifies the page we want' do
      Perpetuity[Article].all.should respond_to :page
    end

    it 'specify the quantity per page' do
      Perpetuity[Article].all.should respond_to :per_page
    end

    it 'returns an empty set when there is no data for that page' do
      mapper = Perpetuity[Article]
      mapper.delete_all
      data = mapper.all.page(2)
      data.should be_empty
    end

    it 'specifies per-page quantity' do
      Perpetuity[Article].delete_all
      5.times { |i| Perpetuity[Article].insert Article.new i }
      data = Perpetuity[Article].all.page(3).per_page(2)
      data.should have(1).item
    end
  end

  describe 'associations with other objects' do
    let(:user) { User.new }
    let(:topic) { Topic.new }
    let(:user_mapper) { Perpetuity[User] }
    let(:topic_mapper) { Perpetuity[Topic] }

    before do
      user.name = 'Flump'
      topic.creator = user
      topic.title = 'Title'

      user_mapper.insert user
      topic_mapper.insert topic
    end

    describe 'referenced relationships' do
      let(:creator) { topic_mapper.find(topic.id).creator }
      subject { creator }

      it { should be_a Perpetuity::Reference }
      its(:klass) { should be User }
      its(:id) { should be == user.id }
    end

    it 'can retrieve a one-to-one association' do
      retrieved_topic = topic_mapper.find(topic.id)

      topic_mapper.load_association! retrieved_topic, :creator
      retrieved_topic.creator.name.should eq 'Flump'
    end

    describe 'associations with many objects' do
      let(:pragprogs) { [User.new('Dave'), User.new('Andy')] }
      let(:cuke_authors) { [User.new('Matt'), User.new('Aslak')] }
      let(:pragprog_book) { Book.new("PragProg #{Time.now.to_f}", pragprogs) }
      let(:cuke_book) { Book.new("Cucumber Book #{Time.now.to_f}", cuke_authors) }
      let(:book_mapper) { Perpetuity[Book] }

      before do
        pragprogs.each { |author| Perpetuity[User].insert author }
        book_mapper.insert pragprog_book
      end

      it 'can retrieve a one-to-many association' do
        persisted_book = book_mapper.find(pragprog_book.id)
        book_mapper.load_association! persisted_book, :authors

        persisted_book.authors.first.name.should be == 'Dave'
        persisted_book.authors.last.name.should be == 'Andy'
      end

      it 'can retrieve a many-to-many association' do
        cuke_authors.each { |author| Perpetuity[User].insert author }
        book_mapper.insert cuke_book
        book_ids = [pragprog_book, cuke_book].map(&:id)

        books = book_mapper.select { |book| book.id.in book_ids }.to_a
        book_mapper.load_association! books, :authors
        books.map(&:authors).flatten.map(&:name).should include *%w(Dave Andy Matt Aslak)
      end
    end
  end

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
  end

  describe 'validations' do
    let(:car_mapper) { Perpetuity[Car] }

    it 'raises an exception when inserting an invalid object' do
      car = Car.new
      expect { car_mapper.insert car }.to raise_error
    end

    it 'does not raise an exception when validations are met' do
      car = Car.new
      car.make = "Volkswagen"
      expect { car_mapper.insert car }.not_to raise_error
    end
  end

  # The Message class stores its data members differently internally than it receives them
  it 'uses accessor methods to read/write data' do
    message = Message.new 'My Message!'
    Perpetuity[Message].insert message
    saved_message = Perpetuity[Message].find(message.id)
    saved_message.instance_variable_get(:@text).should eq 'My Message!'.reverse
    saved_message.text.should eq 'My Message!'
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
