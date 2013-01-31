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
        paginated.result_page.should == 2
      end

      it 'defaults to 20 items per page' do
        paginated.quantity_per_page.should == 20
      end

      it 'sets the number of items per page' do
        paginated.per_page(50).quantity_per_page.should == 50
      end
    end

    it 'retrieves data from the data source' do
      return_data = { id: 0, a: 1, b: 2 }
      options = { attribute: nil, direction: nil, limit: nil, page: nil }
      data_source.should_receive(:retrieve).with(Object, {}, options).
                  and_return([return_data])
      results = retrieval.to_a

      results.map(&:id).should == [0]
    end

    describe 'unserializes attributes' do
      let(:unserializable_object) { 1.to_c }
      let(:serialized_attrs) { [ Marshal.dump(unserializable_object) ] }
      let(:comments) { retrieval.unserialize(serialized_attrs)  }
      subject { comments.first }

      it { should be_a Complex }
      it { should eq unserializable_object}
    end
  end
end
