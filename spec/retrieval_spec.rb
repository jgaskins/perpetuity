require "perpetuity"
require "test_classes"

describe Perpetuity::Retrieval do
  let(:retrieval) { Perpetuity::Retrieval.new Article, {} }
  subject { retrieval }

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
    sorted = retrieval.sort(:name)
    sorted.sort_attribute.should == :name
  end

  it "reverses the sort order of the results" do
    sorted = retrieval.sort(:name).reverse
    sorted.sort_direction.should == :descending
  end
  
  it "limits the result set" do
    retrieval.limit(1).result_limit.should == 1
  end

  it 'indicates whether it includes a specific item' do
    subject.stub(to_a: [1])
    subject.should include 1
  end
end
