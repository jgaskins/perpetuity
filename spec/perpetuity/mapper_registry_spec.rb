require 'perpetuity/mapper_registry'

module Perpetuity
  describe MapperRegistry do
    let(:registry) { MapperRegistry.new }
    let(:mapper) { Class.new { def initialize(map_reg); end } }
    subject { registry }

    before { registry[Object] = mapper }

    it { should have_mapper Object }
    it 'maps classes to instances of their mappers' do
      registry[Object].should be_a mapper
    end

    it 'raises a KeyError when trying to find a mapper for a missing class' do
      expect { registry[Class] }.to raise_error KeyError, 'No mapper for Class'
    end
  end
end
