require 'perpetuity/mapper_registry'
require 'perpetuity/mapper'

module Perpetuity
  describe MapperRegistry do
    let(:registry) { MapperRegistry.new }
    let(:mapper) { Mapper }
    subject { registry }

    before { registry[Object] = mapper }

    it { should have_mapper Object }
    it 'maps classes to instances of their mappers' do
      expect(registry[Object]).to be_a mapper
    end

    it 'raises a KeyError when trying to find a mapper for a missing class' do
      expect { registry[Class] }.to raise_error KeyError, 'No mapper for Class'
    end

    describe 'searching for specified mapper when it is not in the registry' do
      let(:mapper_file) { 'app/mappers/status_mapper.rb' }

      before do
        stub_const 'Status', Class.new
      end

      it 'loads the definition for the specified mapper class' do
        expect(Dir).to receive(:[]).with('app/**/*_mapper.rb') { [mapper_file] }
        expect(registry).to receive(:load).with(mapper_file)
        registry.load_mappers
      end
    end

    it 'returns a mapper initialized with the specified identity map' do
      identity_map = double('IdentityMap')
      mapper = registry.mapper_for(Object, identity_map: identity_map)
      expect(mapper.identity_map).to be identity_map
    end
  end
end
