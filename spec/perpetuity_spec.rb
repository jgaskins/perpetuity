$:.unshift('lib').uniq!
require 'perpetuity'
require 'test_classes'

describe Perpetuity do
  before(:all) do
    # Use MongoDB for now as its the only one supported.
    mongodb = Perpetuity::MongoDB.new db: 'perpetuity_gem_test'
    Perpetuity.configure { data_source mongodb }
  end

  describe 'persistence' do
    it "persists an object" do
      article = Article.new 'I have a title'
      expect { ArticleMapper.insert article }.
        to change { ArticleMapper.count }.by 1
      ArticleMapper.find(article.id).title.should == 'I have a title'
    end

    it 'returns the id of the persisted object' do
      article = Article.new
      ArticleMapper.insert(article).should == article.id
    end

    it "gives an id to objects" do
      article = Article.new
      ArticleMapper.give_id_to article, 1

      article.id.should == 1
    end

    describe 'id injection' do
      let(:article) { Article.new }

      it 'assigns an id to the inserted object' do
        ArticleMapper.insert article
        article.should respond_to :id
      end

      it "assigns an id using Mapper.first" do
        ArticleMapper.first.should respond_to :id
      end

      it 'assigns an id using Mapper.retrieve.first' do
        ArticleMapper.retrieve.first.should respond_to :id
      end

      it 'assigns an id using Mapper.all.first' do
        ArticleMapper.all.first.should respond_to :id
      end
    end

    describe 'persisting arrays' do
      let(:article) { Article.new }

      it 'persists arrays' do
        article.comments << 1 << 2 << 3
        ArticleMapper.insert article
        ArticleMapper.find(article.id).comments.should == [1, 2, 3]
      end

      it 'persists arrays with unserializable objects in them' do
        comment = Comment.new('my comment')
        article.comments << comment
        ArticleMapper.insert article
        ArticleMapper.find(article.id).comments.first.tap do |persisted_comment|
          persisted_comment.should be_a Comment
          persisted_comment.body.should == comment.body
        end
      end
    end

    it "allows mappers to set the id field" do
      book = Book.new(title='My Title')

      BookMapper.insert book
      book.id.should == 'my-title'
    end
  end

  describe "deletion" do
    it 'deletes an object' do
      2.times { ArticleMapper.insert Article.new }
      expect { ArticleMapper.delete ArticleMapper.first }.
        to change { ArticleMapper.count }.by -1
    end

    it 'deletes an object with a given id' do
      article_id = ArticleMapper.insert Article.new
      expect {
        ArticleMapper.delete article_id
      }.to change { ArticleMapper.count }.by -1
    end
    
    describe "#delete_all" do
      it "should delete all objects of a certain class" do
        ArticleMapper.insert Article.new
        ArticleMapper.delete_all
        ArticleMapper.count.should == 0
      end
    end
  end

  describe "retrieval" do
    it "gets all the objects of a class" do
      expect { ArticleMapper.insert Article.new }.
        to change { ArticleMapper.all.count }.by 1
    end
    
    it "has an ID when retrieved" do
      ArticleMapper.insert Article.new
      ArticleMapper.first.should respond_to :id
    end
    
    it "returns a Perpetuity::Retrieval object" do
      ArticleMapper.retrieve(id: 1).should be_an_instance_of Perpetuity::Retrieval
    end

    it "gets an item with a specific ID" do
      article = Article.new
      ArticleMapper.insert article
      retrieved = ArticleMapper.find(article.id)

      retrieved.id.should == article.id
      retrieved.title.should == article.title
      retrieved.body.should == article.body
    end

    it "gets an item by its attributes" do
      article = Article.new
      ArticleMapper.insert article
      retrieved = ArticleMapper.retrieve(title: article.title)

      retrieved.to_a.should_not be_empty
      retrieved.first.title.should == article.title
    end
  end

  describe 'pagination' do
    it 'specifies the page we want' do
      ArticleMapper.retrieve.should respond_to :page
    end

    it 'specify the quantity per page' do
      ArticleMapper.retrieve.should respond_to :per_page
    end

    it 'returns an empty set when there is no data for that page' do
      data = ArticleMapper.retrieve.page(2)
      data.should be_empty
    end

    it 'specifies per-page quantity' do
      ArticleMapper.delete_all
      5.times { |i| ArticleMapper.insert Article.new i }
      data = ArticleMapper.retrieve.page(3).per_page(2)
      data.should have(1).item
    end
  end

  describe 'associations with other objects' do
    class Topic
      attr_accessor :title
      attr_accessor :creator
    end

    class TopicMapper < Perpetuity::Mapper
      attribute :title, String
      attribute :creator, User
    end

    let(:user) { User.new }
    let(:topic) { Topic.new }
    before do
      user.name = 'Flump'
      topic.creator = user
      topic.title = 'Title'

      UserMapper.insert user
      TopicMapper.insert topic
    end

    it 'can reference other objects' do
      TopicMapper.find(topic.id).creator.should == user.id
    end

    it 'can retrieve associated objects' do
      retrieved_topic = TopicMapper.first

      TopicMapper.load_association! retrieved_topic, :creator
      retrieved_topic.creator.name.should == 'Flump'
    end
  end

  describe 'updating' do
    let(:article) { Article.new }
    before do
      ArticleMapper.insert article
    end

    it 'updates an object in the database' do
      ArticleMapper.update article, title: 'I has a new title!'
      ArticleMapper.find(article.id).title.should == 'I has a new title!'
    end
  end

  describe 'instantiation' do
    let!(:article) { Article.new(title = 'My Title') }
    let!(:mapper) { ArticleMapper.new(article) }
    it 'saves data that has changed since last loaded' do
      ArticleMapper.insert article
      article.title = 'My New Title'

      mapper.save

      ArticleMapper.find(article.id).title.should == 'My New Title'
    end

    it 'inserts objects into the DB when instantiated' do
      expect { mapper.insert }.to change { mapper.class.count }.by(1)
    end
  end

  describe 'validations' do
    class Car
      attr_accessor :make, :model, :seats
    end

    class CarMapper < Perpetuity::Mapper
      attribute :make, String
      attribute :model, String
      attribute :seats, Integer

      validate do
        present :make
      end
    end

    it 'raises an exception when inserting an invalid object' do
      car = Car.new
      expect { CarMapper.insert car }.to raise_error
    end

    it 'does not raise an exception when validations are met' do
      car = Car.new
      car.make = "Volkswagen"
      expect { CarMapper.insert car }.not_to raise_error
    end
  end

  # The Message class stores its data members differently internally than it receives them
  it 'uses accessor methods to read/write data' do
    message = Message.new 'My Message!'
    MessageMapper.insert message
    saved_message = MessageMapper.find(message.id)
    saved_message.instance_variable_get(:@text).should == 'My Message!'.reverse
    saved_message.text.should == 'My Message!'
  end
end
