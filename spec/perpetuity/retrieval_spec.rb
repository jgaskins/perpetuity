require 'perpetuity/retrieval'

module Perpetuity
  describe Retrieval do
    let(:data_source) { double('data_source') }
    let(:registry) { double('mapper_registry') }
    let(:mapper) { double(mapped_class: Object, data_source: data_source, mapper_registry: registry) }
    let(:retrieval) { Perpetuity::Retrieval.new mapper, {} }
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

    it 'can be empty' do
      retrieval.stub(to_a: [])
      retrieval.should be_empty
    end

    describe 'pagination' do
      let(:paginated) { retrieval.page(2) }
      it 'paginates data' do
        paginated.result_offset.should == 20
      end

      it 'defaults to 20 items per page' do
        paginated.result_limit.should == 20
      end

      it 'sets the number of items per page' do
        paginated.per_page(50).result_limit.should == 50
      end
    end

    it 'retrieves data from the data source' do
      return_data = { id: 0, a: 1, b: 2 }
      return_object = Object.new
      return_object.stub(id: return_data[:id])
      options = { attribute: nil, direction: nil, limit: nil, skip: nil }

      data_source.should_receive(:retrieve).with(Object, {}, options).
                  and_return([return_data])
      data_source.should_receive(:unserialize).with([return_data], mapper) { [return_object] }
      results = retrieval.to_a

      results.map(&:id).should == [0]
    end

    it 'clears results cache' do
      retrieval.result_cache = [1,2,3]
      retrieval.clear_cache
      retrieval.result_cache.should be_nil
    end
  end
end
