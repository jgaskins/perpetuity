require 'perpetuity/retrieval'
require 'perpetuity/mapper'

module Perpetuity
  describe Retrieval do
    let(:data_source) { double('data_source') }
    let(:registry) { double('mapper_registry') }
    let(:mapper) { double(collection_name: 'Object', data_source: data_source, mapper_registry: registry) }
    let(:query) { double('Query', to_db: {}) }
    let(:retrieval) { Perpetuity::Retrieval.new mapper, query }
    subject { retrieval }

    it "sorts the results" do
      sorted = retrieval.sort(:name)
      expect(sorted.sort_attribute).to be == :name
    end

    it "reverses the sort order of the results" do
      sorted = retrieval.sort(:name).reverse
      expect(sorted.sort_direction).to be == :descending
    end
    
    it "limits the result set" do
      expect(retrieval.limit(1).result_limit).to be == 1
    end

    it 'indicates whether it includes a specific item' do
      allow(subject).to receive(:to_a) { [1] }
      expect(subject).to include 1
    end

    it 'can be empty' do
      allow(retrieval).to receive(:to_a) { [] }
      expect(retrieval).to be_empty
    end

    describe 'pagination' do
      let(:paginated) { retrieval.page(2) }
      it 'paginates data' do
        expect(paginated.result_offset).to be == 20
      end

      it 'defaults to 20 items per page' do
        expect(paginated.result_limit).to be == 20
      end

      it 'sets the number of items per page' do
        expect(paginated.per_page(50).result_limit).to be == 50
      end
    end

    it 'retrieves data from the data source' do
      return_data = { id: 0, a: 1, b: 2 }
      return_object = Object.new
      allow(return_object).to receive(:id) { return_data[:id] }
      options = { attribute: nil, direction: nil, limit: nil, skip: nil }

      expect(data_source).to receive(:retrieve).with('Object', query, options).
                  and_return([return_data])
      expect(data_source).to receive(:unserialize).with([return_data], mapper) { [return_object] }
      allow(mapper).to receive(:id_for)
      results = retrieval.to_a

      expect(results.map(&:id)).to be == [0]
    end

    it 'clears results cache' do
      retrieval.result_cache = [1,2,3]
      retrieval.clear_cache
      expect(retrieval.result_cache).to be_nil
    end

    describe 'identity map' do
      let(:id_map) { IdentityMap.new }
      let(:retrieval) { Retrieval.new(mapper, query, identity_map: id_map) }

      it 'maintains an identity_map' do
        expect(retrieval.identity_map).to be id_map
      end

      it 'returns objects from the identity map with queries' do
        result = Object.new
        result.instance_variable_set :@id, '1'
        id_map << result
        allow(mapper).to receive(:id_for) { '1' }
        allow(data_source).to receive(:retrieve)
        allow(data_source).to receive(:unserialize) { [result.dup] }

        expect(retrieval.to_a).to include result
      end
    end
  end
end
