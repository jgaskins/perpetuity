require "mapper"

# This will be the class we'll be persisting to test this out.
class Article
  attr_reader :title, :body
  def initialize title="Title", body="Body"
    @title = title
    @body = body
  end
end

describe Mapper::MongoDB do
  let(:mongodb) { Mapper::MongoDB.new db: 'mapper_gem_test' }
  
  before(:all) do
    Mapper.config.data_source = mongodb
  end
  
  before(:each) do
    collections_to_drop = mongodb.database.collections.reject{ |coll| coll.name == 'system.indexes' }
    collections_to_drop.each do |collection|
      mongodb.database.drop_collection collection.name
    end
  end
  
  it "saves an object" do
    article = Article.new
    article_mapper = Mapper.new(article)
    article_mapper.insert
    
    Mapper.count(Article).should == 1
    saved_article = Mapper.all(Article)[0]
    saved_article.title.should == article.title
    saved_article.body.should == article.body
  end
  
  it "deletes all instances of a class" do
    Mapper.new(Article.new).insert
    Mapper.delete Article
    Mapper.all(Article).should be_empty
  end
  
  
end