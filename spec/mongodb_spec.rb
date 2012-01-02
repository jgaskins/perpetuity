require "perpetuity"
require 'test_classes'

describe Perpetuity::MongoDB do
  let(:mongodb) { Perpetuity::MongoDB.new db: 'perpetuity_gem_test' }
  
  before(:all) do
    Perpetuity.config.data_source = mongodb
  end
  
  before(:each) do
    collections_to_drop = mongodb.database.collections.reject{ |coll| coll.name == 'system.indexes' }
    collections_to_drop.each do |collection|
      mongodb.database.drop_collection collection.name
    end
  end
  
  it "saves an object" do
    article = Article.new
    article_perp = Perpetuity.new(article)
    article_perp.insert
    
    Perpetuity.count(Article).should == 1
    saved_article = Perpetuity.all(Article)[0]
    saved_article.title.should == article.title
    saved_article.body.should == article.body
  end
  
  it "deletes all instances of a class" do
    Perpetuity.new(Article.new).insert
    Perpetuity.delete Article
    Perpetuity.all(Article).should be_empty
  end
  
  
end