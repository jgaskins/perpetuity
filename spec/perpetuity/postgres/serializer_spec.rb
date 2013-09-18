require 'perpetuity/postgres/serializer'
require 'perpetuity/mapper'
require 'support/test_classes/user'

module Perpetuity
  class Postgres
    describe Serializer do
      let(:registry) { {} }
      let(:mapper_class) do
        registry = self.registry
        Class.new(Mapper) do
          map User, registry
          attribute :name, type: String
        end
      end
      let(:mapper) { mapper_class.new(registry) }
      let(:serializer) { Serializer.new(mapper) }

      it 'serializes simple objects' do
        serializer.serialize(User.new('Jamie')).should == { 'name' => 'Jamie' }
      end
    end
  end
end
