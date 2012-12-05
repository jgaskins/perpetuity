require 'perpetuity/mapper_registry'

module Perpetuity
  describe MapperRegistry do
    subject { described_class }
    let(:mapper) { Class.new }

    before { MapperRegistry[Object] = mapper }

    it { should have_mapper Object }
    it 'maps classes to instances of their mappers' do
      MapperRegistry[Object].should be_a mapper
    end
  end
end
