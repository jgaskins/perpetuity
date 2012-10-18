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
      expect { Perpetuity::Mapper[Article].insert article }.
        to change { Perpetuity::Mapper[Article].count }.by 1
      Perpetuity::Mapper[Article].find(article.id).title.should eq 'I have a title'
    end

    it 'returns the id of the persisted object' do
      article = Article.new
      Perpetuity::Mapper[Article].insert(article).should eq article.id
    end

    it "gives an id to objects" do
      article = Article.new
      Perpetuity::Mapper[Article].give_id_to article, 1

      article.id.should eq 1
    end

    describe 'id injection' do
      let(:article) { Article.new }

      it 'assigns an id to the inserted object' do
        Perpetuity::Mapper[Article].insert article
        article.should respond_to :id
      end

      it "assigns an id using Mapper.first" do
        Perpetuity::Mapper[Article].first.should respond_to :id
      end

      it 'assigns an id using Mapper.retrieve.first' do
        Perpetuity::Mapper[Article].retrieve.first.should respond_to :id
      end

      it 'assigns an id using Mapper.all.first' do
        Perpetuity::Mapper[Article].all.first.should respond_to :id
      end
    end

    describe 'persisting arrays' do
      let(:article) { Article.new }

      it 'persists arrays' do
        article.comments << 1 << 2 << 3
        Perpetuity::Mapper[Article].insert article
        Perpetuity::Mapper[Article].find(article.id).comments.should eq [1, 2, 3]
      end

      it 'persists arrays with unserializable objects in them' do
        comment = Comment.new('my comment')
        article.comments << comment
        Perpetuity::Mapper[Article].insert article
        Perpetuity::Mapper[Article].find(article.id).comments.first.tap do |persisted_comment|
          persisted_comment.should be_a Comment
          persisted_comment.body.should eq comment.body
        end
      end
    end

    it "allows mappers to set the id field" do
      book = Book.new('My Title')

      Perpetuity::Mapper[Book].insert book
      book.id.should eq 'my-title'
    end
  end

  describe "deletion" do
    it 'deletes an object' do
      2.times { Perpetuity::Mapper[Article].insert Article.new }
      expect { Perpetuity::Mapper[Article].delete Perpetuity::Mapper[Article].first }.to change { Perpetuity::Mapper[Article].count }.by(-1)
    end

    it 'deletes an object with a given id' do
      article_id = Perpetuity::Mapper[Article].insert Article.new
      expect {
        Perpetuity::Mapper[Article].delete article_id
      }.to change { Perpetuity::Mapper[Article].count }.by(-1)
    end
    
    describe "#delete_all" do
      it "should delete all objects of a certain class" do
        Perpetuity::Mapper[Article].insert Article.new
        Perpetuity::Mapper[Article].delete_all
        Perpetuity::Mapper[Article].count.should eq 0
      end
    end
  end

  describe "retrieval" do
    it "gets all the objects of a class" do
      expect { Perpetuity::Mapper[Article].insert Article.new }.
        to change { Perpetuity::Mapper[Article].all.count }.by 1
    end
    
    it "has an ID when retrieved" do
      Perpetuity::Mapper[Article].insert Article.new
      Perpetuity::Mapper[Article].first.should respond_to :id
    end
    
    it "returns a Perpetuity::Retrieval object" do
      Perpetuity::Mapper[Article].retrieve(id: 1).should be_an_instance_of Perpetuity::Retrieval
    end

    it "gets an item with a specific ID" do
      article = Article.new
      Perpetuity::Mapper[Article].insert article
      retrieved = Perpetuity::Mapper[Article].find(article.id)

      retrieved.id.should eq article.id
      retrieved.title.should eq article.title
      retrieved.body.should eq article.body
    end

    it "gets an item by its attributes" do
      article = Article.new
      Perpetuity::Mapper[Article].insert article
      retrieved = Perpetuity::Mapper[Article].retrieve(title: article.title)

      retrieved.to_a.should_not be_empty
      retrieved.first.title.should eq article.title
    end

    describe "Array-like syntax" do
      let(:draft) { Article.new 'Draft', 'draft content', nil, Time.now + 30 }
      let(:published) { Article.new 'Published', 'content', nil, Time.now - 30, 3 }
      before do
        Perpetuity::Mapper[Article].insert draft
        Perpetuity::Mapper[Article].insert published
      end

      it 'selects objects using equality' do
        selected = Perpetuity::Mapper[Article].select { title == 'Published' }
        selected.map(&:id).should include published.id
        selected.map(&:id).should_not include draft.id
      end

      it 'selects objects using greater-than' do
        selected = Perpetuity::Mapper[Article].select { published_at < Time.now }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end

      it 'selects objects using greater-than-or-equal' do
        selected = Perpetuity::Mapper[Article].select { views >= 3 }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end

      it 'selects objects using less-than' do
        selected = Perpetuity::Mapper[Article].select { views < 3 }
        ids = selected.map(&:id)
        ids.should include draft.id
        ids.should_not include published.id
      end

      it 'selects objects using less-than-or-equal' do
        selected = Perpetuity::Mapper[Article].select { views <= 0 }
        ids = selected.map(&:id)
        ids.should include draft.id
        ids.should_not include published.id
      end

      it 'selects objects using inequality' do
        selected = Perpetuity::Mapper[Article].select { title.not_equal? 'Draft' }
        ids = selected.map(&:id)
        ids.should_not include draft.id
        ids.should include published.id
      end

      it 'selects objects using regular expressions' do
        selected = Perpetuity::Mapper[Article].select { title =~ /Pub/ }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end

      it 'selects objects using inclusion' do
        selected = Perpetuity::Mapper[Article].select { title.in %w( Published ) }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end
    end
  end

  describe 'pagination' do
    it 'specifies the page we want' do
      Perpetuity::Mapper[Article].retrieve.should respond_to :page
    end

    it 'specify the quantity per page' do
      Perpetuity::Mapper[Article].retrieve.should respond_to :per_page
    end

    it 'returns an empty set when there is no data for that page' do
      data = Perpetuity::Mapper[Article].retrieve.page(2)
      data.should be_empty
    end

    it 'specifies per-page quantity' do
      Perpetuity::Mapper[Article].delete_all
      5.times { |i| Perpetuity::Mapper[Article].insert Article.new i }
      data = Perpetuity::Mapper[Article].retrieve.page(3).per_page(2)
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

      Perpetuity::Mapper[User].insert user
      Perpetuity::Mapper[Topic].insert topic
    end

    it 'can reference other objects' do
      Perpetuity::Mapper[Topic].find(topic.id).creator.should eq user.id
    end

    it 'can retrieve associated objects' do
      retrieved_topic = Perpetuity::Mapper[Topic].first

      Perpetuity::Mapper[Topic].load_association! retrieved_topic, :creator
      retrieved_topic.creator.name.should eq 'Flump'
    end
  end

  describe 'updating' do
    let(:article) { Article.new }
    before do
      Perpetuity::Mapper[Article].insert article
    end

    it 'updates an object in the database' do
      Perpetuity::Mapper[Article].update article, title: 'I has a new title!'
      Perpetuity::Mapper[Article].find(article.id).title.should eq 'I has a new title!'
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
      expect { Perpetuity::Mapper[Car].insert car }.to raise_error
    end

    it 'does not raise an exception when validations are met' do
      car = Car.new
      car.make = "Volkswagen"
      expect { Perpetuity::Mapper[Car].insert car }.not_to raise_error
    end
  end

  # The Message class stores its data members differently internally than it receives them
  it 'uses accessor methods to read/write data' do
    message = Message.new 'My Message!'
    Perpetuity::Mapper[Message].insert message
    saved_message = Perpetuity::Mapper[Message].find(message.id)
    saved_message.instance_variable_get(:@text).should eq 'My Message!'.reverse
    saved_message.text.should eq 'My Message!'
  end
end
