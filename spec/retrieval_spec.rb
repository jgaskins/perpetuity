require "perpetuity"
require "test_classes"

describe Perpetuity::Retrieval do
  subject { Perpetuity::Retrieval.new Article, {} }

  before(:all) do
    Perpetuity.configure do
      data_source Perpetuity::MongoDB.new db: 'perpetuity_gem_test'
    end
  end

  before(:each) do
    ArticleMapper.delete_all
    UserMapper.delete_all
  end

  it "sorts the results" do
    ArticleMapper.insert Article.new('B')
    ArticleMapper.insert Article.new('A')
    ArticleMapper.insert Article.new('C')
    
    subject.sort(:title).map(&:title).should == %w(A B C)
  end

  it "reverses the sort order of the results" do
    ArticleMapper.insert Article.new('B')
    ArticleMapper.insert Article.new('A')
    ArticleMapper.insert Article.new('C')
    
    subject.sort(:title).reverse.map(&:title).should == %w(C B A)
  end
  
  it "limits the result set" do
    2.times { ArticleMapper.insert Article.new }
    ArticleMapper.retrieve.limit(1).count.should == 1
  end

  it 'indicates whether it includes a specific item' do
    subject.stub(to_a: [1])
    subject.should include 1
  end
end
