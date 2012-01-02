require 'perpetuity'

class Article
  attr_reader :title, :body
  def initialize title='Title', body='body'
    @title = title
    @body = body
  end
end

describe Perpetuity do
  let(:mongodb) { Perpetuity::MongoDB.new db: 'perpetuity_gem_test' }
  before(:all) do
    # Use MongoDB for now as its the only one supported.
    Perpetuity.config.data_source = mongodb
    Perpetuity.delete Article
  end

  it "takes an object param in the constructor" do
    expect { perp = Perpetuity.new Object.new }.to_not raise_error
  end

  it "can be associated with a MongoDB" do
    Perpetuity.config.data_source.should == mongodb
  end
  
  it "gets an object's attributes" do
    article = Article.new
    article_perp = Perpetuity.new(article)
    article_perp.object_attributes.keys.should include :@title
    article_perp.object_attributes.keys.should include :@body
  end
  
  it "persists an object" do
    article = Article.new
    article_perp = Perpetuity.new(article)
    article_perp.insert
    Perpetuity.count(Article).should == 1
  end
  
  it "deletes an object" do
    Perpetuity.new(Article.new).insert
    Perpetuity.delete Article
    Perpetuity.count(Article).should == 0
  end
  
  it "gets all the objects of a class" do
    Perpetuity.new(Article.new).insert
    Perpetuity.all(Article).length.should == 1
  end
  
  it "returns a Perpetuity::Retrieval object" do
    Perpetuity.retrieve(Article, id: 1).should be_an_instance_of Perpetuity::Retrieval
  end

  it "gets an item with a specific ID" do
    Perpetuity.new(Article.new).insert
    article = Perpetuity.all(Article)[0]
    retrieved = Perpetuity.retrieve(Article, id: article.instance_variable_get(:@_id))[0]
    
    retrieved.instance_variable_get(:@_id).should == article.instance_variable_get(:@_id)
    retrieved.title.should == article.title
    retrieved.body.should == article.body
  end
end