require 'perpetuity'
require "test_classes"

describe Perpetuity::Mapper do
  before(:all) do
    # Use MongoDB for now as its the only one supported.
    mongodb = Perpetuity::MongoDB.new db: 'perpetuity_gem_test'
    Perpetuity.configure { data_source mongodb }
  end

  before(:each) do
    ArticleMapper.delete_all
  end

  it "has correct attributes" do
    UserMapper.attributes.should == [:name]
    ArticleMapper.attributes.should == [:title, :body, :views]
  end

  it "knows which class it maps" do
    ArticleMapper.mapped_class.should == Article
  end

  describe 'persistence' do
    it "persists an object" do
      article = Article.new 'I have a title'
      ArticleMapper.insert article
      ArticleMapper.count.should == 1
      ArticleMapper.first.title.should == 'I have a title'
    end

    it "gives an id to objects" do
      article = Article.new
      ArticleMapper.give_id_to article, 1

      article.id.should == 1
    end

    it "assigns an id to persisted objects" do
      article = Article.new
      ArticleMapper.insert article

      [ArticleMapper.first, ArticleMapper.retrieve.first, ArticleMapper.all.first].each do |persisted_article|
        article.id.should == persisted_article.id
      end
    end

    it "allows mappers to set the id field" do
      BookMapper.delete_all
      book = Book.new(title='My Title')

      BookMapper.insert book
      BookMapper.first.id.should == 'my-title'
    end

    it "checks for object validity before persisting" do
      invalid_article = Article.new(title=nil)
      invalid_article.stub(valid?: nil)
      expect { ArticleMapper.insert(invalid_article) }.to raise_error
    end
  end

  describe "deletion" do
    it 'deletes an object' do
      2.times { ArticleMapper.insert Article.new }
      ArticleMapper.delete ArticleMapper.first
      ArticleMapper.count.should == 1
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
      ArticleMapper.insert Article.new
      ArticleMapper.all.count.should == 1

      ArticleMapper.insert Article.new
      ArticleMapper.all.count.should == 2
    end
    
    it "has an ID when retrieved" do
      ArticleMapper.insert Article.new
      ArticleMapper.first.id.should_not be_nil
    end
    
    it "returns a Perpetuity::Retrieval object" do
      ArticleMapper.retrieve(id: 1).should be_an_instance_of Perpetuity::Retrieval
    end

    it "gets an item with a specific ID" do
      ArticleMapper.insert Article.new
      article = ArticleMapper.first
      retrieved = ArticleMapper.find(article.id)

      retrieved.id.should == article.id
      retrieved.title.should == article.title
      retrieved.body.should == article.body
    end

    it "gets an item by its attributes" do
      article = Article.new
      ArticleMapper.insert article
      retrieved = ArticleMapper.retrieve(title: article.title)

      retrieved.to_a.should have(1).item
      retrieved.first.title.should == article.title
    end

    context "using inequalities" do
      let(:popular_article) { Article.new title='popular!' }
      let(:unpopular_article) { Article.new title='unpopular :-(' }
      before do
        popular_article.views = 1000
        unpopular_article.views = 10
        ArticleMapper.insert popular_article
        ArticleMapper.insert unpopular_article
      end

      it "less than" do
        ArticleMapper.retrieve(:views < 100).map(&:id).should == [unpopular_article.id]
      end

      it "less than or equal" do
        ArticleMapper.retrieve(:views <= 1000).map(&:id).should include popular_article.id, unpopular_article.id
        ArticleMapper.retrieve(:views <= 10).map(&:id).should == [unpopular_article.id]
      end

      it "greater than or equal" do
        ArticleMapper.retrieve(:views >= 1000).map(&:id).should == [popular_article.id]
        ArticleMapper.retrieve(:views >= 10).map(&:id).should include popular_article.id, unpopular_article.id
      end

      it "greater than" do
        ArticleMapper.retrieve(:views > 100).map(&:id).should == [popular_article.id]
      end
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
      TopicMapper.delete_all
      UserMapper.delete_all

      user.name = 'Flump'
      topic.creator = user
      topic.title = 'Title'

      UserMapper.insert user
      TopicMapper.insert topic
    end

    it 'can reference other objects' do
      TopicMapper.first.creator.should == user.id
    end

    it 'can retrieve associated objects' do
      topic = TopicMapper.first

      TopicMapper.load_association! topic, :creator
      topic.creator.name.should == 'Flump'
    end
  end

  # The Message class stores its data members differently internally than it receives them
  it 'uses accessor methods to read/write data' do
    MessageMapper.delete_all

    message = Message.new 'My Message!'
    MessageMapper.insert message
    saved_message = MessageMapper.first
    saved_message.instance_variable_get(:@text).should == 'My Message!'.reverse
    saved_message.text.should == 'My Message!'
  end

  describe 'updating' do
    let(:article) { Article.new }
    before do
      ArticleMapper.insert article
    end

    it 'updates an object in the database' do
      ArticleMapper.update article, title: 'I has a new title!'
      ArticleMapper.first.title.should == 'I has a new title!'
    end
  end

  describe 'instantiation' do
    let!(:article) { Article.new(title = 'My Title') }
    let!(:mapper) { ArticleMapper.new(article) }

    it 'can be instantiated' do
      mapper.object.title.should == 'My Title'
    end

    it 'duplicates the object when instantiated' do
      article.title = 'My New Title'

      mapper.original_object.title.should == 'My Title'
      mapper.object.title.should == 'My New Title'
    end

    it 'knows what data has changed since last loaded' do
      article.title = 'My New Title'

      mapper.changed_attributes.should == { title: 'My New Title' }
    end

    it 'saves data that has changed since last loaded' do
      ArticleMapper.insert article
      article.title = 'My New Title'

      mapper.save

      ArticleMapper.first.title.should == 'My New Title'
    end

    describe 'validations' do
      class Car
        attr_accessor :make, :model
      end

      class CarMapper < Perpetuity::Mapper
        attribute :make, String
        attribute :model, String
        attribute :seats, Integer

        validate do
        end
      end
    end
  end
end
