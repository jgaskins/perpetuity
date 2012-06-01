require 'perpetuity/retrieval'

describe Perpetuity::Retrieval do
  let(:data_source) { double('data_source') }
  let(:retrieval) { Perpetuity::Retrieval.new Object, {}, data_source }
  subject { retrieval }

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

  it 'retrieves data from the data source' do
    return_object = Object.new
    options = { attribute: nil, direction: nil, limit: nil }
    data_source.should_receive(:retrieve).with(Object, {}, options).
                and_return([return_object])
    results = retrieval.to_a

    results.should == [return_object]
  end
end
