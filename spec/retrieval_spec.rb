require "perpetuity"
require "test_classes"

describe Perpetuity::Retrieval do
  subject { Perpetuity::Retrieval.new Article, {} }
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
  
  it "sorts the results" do
    Perpetuity.new(Article.new 'B').insert
    Perpetuity.new(Article.new 'A').insert
    Perpetuity.new(Article.new 'C').insert
    
    subject.sort(:title).map(&:title).should == %w(A B C)
  end
  
  it "reverses the sort order of the results" do
    Perpetuity.new(Article.new 'B').insert
    Perpetuity.new(Article.new 'A').insert
    Perpetuity.new(Article.new 'C').insert
    
    subject.sort(:title).reverse.map(&:title).should == %w(C B A)
  end
end