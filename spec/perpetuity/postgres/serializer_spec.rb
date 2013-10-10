require 'perpetuity/postgres/serializer'
require 'perpetuity/mapper'
require 'support/test_classes/book'

module Perpetuity
  class Postgres
    describe Serializer do
      let(:registry) { {} }
      let(:mapper_class) do
        registry = self.registry
        Class.new(Mapper) do
          map Book, registry
          attribute :title, type: String
          attribute :authors, type: Array
        end
      end
      let(:mapper) { mapper_class.new(registry) }
      let(:serializer) { Serializer.new(mapper) }

      it 'serializes simple objects' do
        serializer.serialize(Book.new('Foo')).should == %q{('Foo','[]')}
      end

      it 'serializes an array as JSON' do
        serializer.serialize_array([1, 'foo']).should == %q{'[1, "foo"]'}
      end

      it 'serializes nested objects' do
        serializer.serialize_attribute('string').should == "'string'"
        serializer.serialize_attribute(1).should == 1
        serializer.serialize_attribute(nil).should == 'NULL'
        serializer.serialize_attribute(true).should == 'TRUE'
        serializer.serialize_attribute(false).should == 'FALSE'
      end
    end
  end
end
