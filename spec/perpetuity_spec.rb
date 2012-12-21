require 'perpetuity'
require 'test_classes'

describe Perpetuity do
  before(:all) do
    # Use MongoDB for now as its the only one supported.
    mongodb = Perpetuity::MongoDB.new db: 'perpetuity_gem_test'
    Perpetuity.configure { data_source mongodb }
  end

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

  describe 'persistence' do
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

    describe 'id injection' do
      let(:article) { Article.new }

      it 'assigns an id to the inserted object' do
        Perpetuity[Article].insert article
        article.should respond_to :id
      end

      it "assigns an id using Mapper.first" do
        Perpetuity[Article].first.should respond_to :id
      end

      it 'assigns an id using Mapper.retrieve.first' do
        Perpetuity[Article].retrieve.first.should respond_to :id
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

    it "allows mappers to set the id field" do
      noise = Time.now.to_f.to_s.sub('.', '')
      book = Book.new("My Title #{noise}")

      Perpetuity[Book].insert book
      book.id.should eq "my-title-#{noise}"
    end
  end

  describe "deletion" do
    it 'deletes an object' do
      2.times { Perpetuity[Article].insert Article.new }
      expect { Perpetuity[Article].delete Perpetuity[Article].first }.to change { Perpetuity[Article].count }.by(-1)
    end

    it 'deletes an object with a given id' do
      article_id = Perpetuity[Article].insert Article.new
      expect {
        Perpetuity[Article].delete article_id
      }.to change { Perpetuity[Article].count }.by(-1)
    end
    
    describe "#delete_all" do
      it "should delete all objects of a certain class" do
        Perpetuity[Article].insert Article.new
        Perpetuity[Article].delete_all
        Perpetuity[Article].count.should eq 0
      end
    end
  end

  describe "retrieval" do
    it "gets all the objects of a class" do
      expect { Perpetuity[Article].insert Article.new }.
        to change { Perpetuity[Article].all.count }.by 1
    end
    
    it "has an ID when retrieved" do
      Perpetuity[Article].insert Article.new
      Perpetuity[Article].first.should respond_to :id
    end
    
    it "returns a Perpetuity::Retrieval object" do
      Perpetuity[Article].retrieve(id: 1).should be_an_instance_of Perpetuity::Retrieval
    end

    it "gets an item with a specific ID" do
      article = Article.new
      Perpetuity[Article].insert article
      retrieved = Perpetuity[Article].find(article.id)

      retrieved.id.should eq article.id
      retrieved.title.should eq article.title
      retrieved.body.should eq article.body
    end

    it "gets an item by its attributes" do
      article = Article.new
      Perpetuity[Article].insert article
      retrieved = Perpetuity[Article].retrieve(title: article.title)

      retrieved.to_a.should_not be_empty
      retrieved.first.title.should eq article.title
    end

    describe "Array-like syntax" do
      let(:draft) { Article.new 'Draft', 'draft content', nil, Time.now + 30 }
      let(:published) { Article.new 'Published', 'content', nil, Time.now - 30, 3 }
      before do
        Perpetuity[Article].insert draft
        Perpetuity[Article].insert published
      end

      it 'selects objects using equality' do
        selected = Perpetuity[Article].select { title == 'Published' }
        selected.map(&:id).should include published.id
        selected.map(&:id).should_not include draft.id
      end

      it 'selects objects using greater-than' do
        selected = Perpetuity[Article].select { published_at < Time.now }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end

      it 'selects objects using greater-than-or-equal' do
        selected = Perpetuity[Article].select { views >= 3 }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end

      it 'selects objects using less-than' do
        selected = Perpetuity[Article].select { views < 3 }
        ids = selected.map(&:id)
        ids.should include draft.id
        ids.should_not include published.id
      end

      it 'selects objects using less-than-or-equal' do
        selected = Perpetuity[Article].select { views <= 0 }
        ids = selected.map(&:id)
        ids.should include draft.id
        ids.should_not include published.id
      end

      it 'selects objects using inequality' do
        selected = Perpetuity[Article].select { title.not_equal? 'Draft' }
        ids = selected.map(&:id)
        ids.should_not include draft.id
        ids.should include published.id
      end

      it 'selects objects using regular expressions' do
        selected = Perpetuity[Article].select { title =~ /Pub/ }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end

      it 'selects objects using inclusion' do
        selected = Perpetuity[Article].select { title.in %w( Published ) }
        ids = selected.map(&:id)
        ids.should include published.id
        ids.should_not include draft.id
      end
    end
  end

  describe 'pagination' do
    it 'specifies the page we want' do
      Perpetuity[Article].retrieve.should respond_to :page
    end

    it 'specify the quantity per page' do
      Perpetuity[Article].retrieve.should respond_to :per_page
    end

    it 'returns an empty set when there is no data for that page' do
      mapper = Perpetuity[Article]
      mapper.delete_all
      data = mapper.retrieve.page(2)
      data.should be_empty
    end

    it 'specifies per-page quantity' do
      Perpetuity[Article].delete_all
      5.times { |i| Perpetuity[Article].insert Article.new i }
      data = Perpetuity[Article].retrieve.page(3).per_page(2)
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

    it 'can retrieve associated objects' do
      retrieved_topic = topic_mapper.find(topic.id)

      topic_mapper.load_association! retrieved_topic, :creator
      retrieved_topic.creator.name.should eq 'Flump'
    end
  end

  describe 'updating' do
    let(:article) { Article.new }
    let(:mapper) { Perpetuity[Article] }
    let(:new_title) { 'I has a new title!' }

    before do
      mapper.insert article
      mapper.update article, title: new_title
    end

    it 'updates an object in the database' do
      mapper.find(article.id).title.should eq new_title
    end

    it 'updates the object in memory' do
      article.title.should eq new_title
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
        index :name
      end
    end
    let(:mapper) { mapper_class.new }
    let(:name_index) do
      mapper.indexes.find do |index|
        index.attribute.to_s == :name
      end
    end

    it 'adds indexes to database collections/tables' do
      name_index.attribute.name.should be == :name
    end

    it 'verifies that indexes are inactive' do
      name_index.should be_inactive
    end

    it 'creates indexes' do
      mapper.reindex!
      name_index.should be_active
    end
  end
end
