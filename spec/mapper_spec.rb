require 'mapper'

class Article
  attr_reader :title, :body
  def initialize title='Title', body='body'
    @title = title
    @body = body
  end
end

describe Mapper do
  let(:mongodb) { Mapper::MongoDB.new db: 'mapper_gem_test' }
  before(:all) do
    # Use MongoDB for now as its the only one supported.
    Mapper.config.data_source = mongodb
    Mapper.delete Article
  end

  it "takes an object param in the constructor" do
    expect { mapper = Mapper.new Object.new }.to_not raise_error
  end

  it "can be associated with a MongoDB" do
    Mapper.config.data_source.should == mongodb
  end
  
  it "gets an object's attributes" do
    article = Article.new
    article_mapper = Mapper.new(article)
    article_mapper.object_attributes.keys.should include :@title
    article_mapper.object_attributes.keys.should include :@body
  end
  
  it "persists an object" do
    article = Article.new
    article_mapper = Mapper.new(article)
    article_mapper.insert
    Mapper.count(Article).should == 1
  end
  
  it "deletes an object" do
    Mapper.new(Article.new).insert
    Mapper.delete Article
    Mapper.count(Article).should == 0
  end
  
  it "gets all the objects of a class" do
    Mapper.new(Article.new).insert
    Mapper.all(Article).length.should == 1
  end
  
  it "gets an item with a specific ID" do
    Mapper.new(Article.new).insert
    article = Mapper.all(Article)[0]
    retrieved = Mapper.retrieve(Article, id: article.instance_variable_get(:@_id))[0]
    
    retrieved.instance_variable_get(:@_id).should == article.instance_variable_get(:@_id)
    retrieved.title.should == article.title
    retrieved.body.should == article.body
  end
end