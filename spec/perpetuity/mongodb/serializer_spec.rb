require 'perpetuity/mongodb/serializer'
require 'perpetuity/mapper'
require 'perpetuity/mapper_registry'
require 'support/test_classes/book'
require 'support/test_classes/user'
require 'support/test_classes/car'

module Perpetuity
  class MongoDB
    describe Serializer do
      let(:dave) { User.new('Dave') }
      let(:andy) { User.new('Andy') }
      let(:authors) { [dave, andy] }
      let(:book) { Book.new('The Pragmatic Programmer', authors) }
      let(:mapper_registry) { MapperRegistry.new }
      let(:book_mapper) do
        registry = mapper_registry
        Class.new(Perpetuity::Mapper) do
          map Book, registry
          attribute :title
          attribute :authors
        end.new(registry)
      end
      let(:user_mapper) do
        registry = mapper_registry
        Class.new(Perpetuity::Mapper) do
          map User, registry
          attribute :name
        end.new(registry)
      end
      let(:data_source) { double('Data Source') }
      let(:serializer) { Serializer.new(book_mapper) }

      before do
        serializer.give_id_to dave, 1
        serializer.give_id_to andy, 2
      end

      it 'serializes an array of non-embedded attributes as references' do
        user_mapper.stub(data_source: data_source)
        book_mapper.stub(data_source: data_source)
        data_source.should_receive(:can_serialize?).with(book.title).and_return true
        data_source.should_receive(:can_serialize?).with(dave).and_return false
        data_source.should_receive(:can_serialize?).with(andy).and_return false
        serializer.serialize(book).should be == {
          'title' => book.title,
          'authors' => [
            {
              '__metadata__' => {
                'class' => 'User',
                'id' => user_mapper.id_for(dave)
              }
            },
            {
              '__metadata__' => {
                'class' => 'User',
                'id' => user_mapper.id_for(andy)
              }
            }
          ]
        }
      end

      it 'can serialize only changed attributes' do
        book = Book.new('Original Title')
        updated_book = book.dup
        updated_book.title = 'New Title'
        book_mapper.stub(data_source: data_source)
        data_source.stub(:can_serialize?).with('New Title') { true }
        data_source.stub(:can_serialize?).with('Original Title') { true }
        serializer.serialize_changes(updated_book, book).should == {
          'title' => 'New Title'
        }
      end

      context 'with objects that have hashes as attributes' do
        let(:name_data) { {first_name: 'Jamie', last_name: 'Gaskins'} }
        let(:serialized_data) { { 'name' => name_data } }
        let(:user) { User.new(name_data) }
        let(:user_serializer) { Serializer.new(user_mapper) }

        before do
          user_mapper.stub(data_source: data_source)
          book_mapper.stub(data_source: data_source)
          data_source.stub(:can_serialize?).with(name_data) { true }
        end

        it 'serializes' do
          user_serializer.serialize(user).should be == serialized_data
        end

        it 'unserializes' do
          user_serializer.unserialize(serialized_data).name.should be == user.name
        end
      end

      describe 'with an array of references' do
        let(:author) { Reference.new(User, 1) }
        let(:title) { 'title' }
        let(:book) { Book.new(title, [author]) }

        before do
          user_mapper.stub(data_source: data_source)
          book_mapper.stub(data_source: data_source)
        end

        it 'passes the reference unserialized' do
          data_source.should_receive(:can_serialize?).with('title') { true }
          serializer.serialize(book).should == {
            'title' => title,
            'authors' => [{
              '__metadata__' => {
                'class' => author.klass.to_s,
                'id' => author.id
              }
            }]
          }
        end
      end

      context 'with uninitialized attributes' do
        let(:car_model) { 'Corvette' }
        let(:car) { Car.new(model: car_model) }
        let(:mapper) do
          registry = mapper_registry
          Class.new(Mapper) do
            map Car, registry

            attribute :make
            attribute :model
          end.new(registry)
        end
        let(:serializer) { Serializer.new(mapper) }


        it 'does not persist uninitialized attributes' do
          mapper.stub data_source: data_source
          data_source.should_receive(:can_serialize?).with(car_model) { true }

          serializer.serialize(car).should == { 'model' => car_model }
        end
      end

      context 'with marshaled data' do
        let(:unserializable_value) { 1..10 }

        it 'stores metadata with marshal information' do
          book = Book.new(unserializable_value)

          book_mapper.stub(data_source: data_source)
          data_source.stub(:can_serialize?).with(book.title) { false }

          serializer.serialize(book).should == {
            'title' => {
              '__marshaled__' => true,
              'value' => Marshal.dump(unserializable_value)
            },
            'authors' => []
          }
        end

        it 'stores marshaled attributes within arrays' do
          book = Book.new([unserializable_value])
          book_mapper.stub(data_source: data_source)
          data_source.stub(:can_serialize?).with(book.title.first) { false }

          serializer.serialize(book).should == {
            'title' => [{
              '__marshaled__' => true,
              'value' => Marshal.dump(unserializable_value)
            }],
            'authors' => []
          }
        end

        it 'unmarshals data that has been marshaled by the serializer' do
          data = {
            'title' => {
              '__marshaled__' => true,
              'value' => Marshal.dump(unserializable_value),
            }
          }
          serializer.unserialize(data).title.should be_a unserializable_value.class
        end

        it 'does not unmarshal data not marshaled by the serializer' do
          data = { 'title' => Marshal.dump(unserializable_value) }

          serializer.unserialize(data).title.should be_a String
        end
      end

      it 'unserializes a hash of primitives' do
        time = Time.now
        serialized_data = {
          'number' => 1,
          'string' => 'hello',
          'boolean' => true,
          'float' => 7.5,
          'time' => time
        }

        object = serializer.unserialize(serialized_data)
        object.instance_variable_get(:@number).should == 1
        object.instance_variable_get(:@string).should == 'hello'
        object.instance_variable_get(:@boolean).should == true
        object.instance_variable_get(:@float).should == 7.5
        object.instance_variable_get(:@time).should == time
      end
    end
  end
end
