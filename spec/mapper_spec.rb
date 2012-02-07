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
    ArticleMapper.attributes.should == [:title, :body]
  end

  it "knows which class it maps" do
    ArticleMapper.mapped_class.should == Article
  end

  it "persists an object" do
    article = Article.new 'I have a title'
    ArticleMapper.insert article
    ArticleMapper.count.should == 1
    ArticleMapper.first.title.should == 'I have a title'
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
      article = ArticleMapper.all[0]
      retrieved = ArticleMapper.retrieve(id: article.instance_variable_get(:@_id))[0]

      retrieved.instance_variable_get(:@_id).should == article.instance_variable_get(:@_id)
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
  end
end
