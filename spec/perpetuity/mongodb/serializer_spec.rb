require 'perpetuity/mongodb/serializer'
require 'perpetuity/mapper'
require 'perpetuity/mapper_registry'
require 'support/test_classes/book'
require 'support/test_classes/user'

module Perpetuity
  class MongoDB
    describe Serializer do
      let(:dave) { User.new('Dave') }
      let(:andy) { User.new('Andy') }
      let(:authors) { [dave, andy] }
      let(:book) { Book.new('The Pragmatic Programmer', authors) }
      let(:mapper_registry) { MapperRegistry.new }
      let!(:book_mapper_class) do
        registry = mapper_registry
        Class.new(Perpetuity::Mapper) do
          map Book, registry
          attribute :title
          attribute :authors
        end
      end
      let!(:user_mapper_class) do
        registry = mapper_registry
        Class.new(Perpetuity::Mapper) do
          map User, registry
          attribute :name
        end
      end
      let(:data_source) { double('Data Source') }
      let(:serializer) { Serializer.new(mapper_registry[Book]) }

      before do
        dave.extend PersistedObject
        andy.extend PersistedObject
        user_mapper_class.stub(data_source: data_source)
        book_mapper_class.stub(data_source: data_source)
      end

      it 'serializes an array of non-embedded attributes as references' do
        data_source.should_receive(:can_serialize?).with(book.title).and_return true
        data_source.should_receive(:can_serialize?).with(dave).and_return false
        data_source.should_receive(:can_serialize?).with(andy).and_return false
        serializer.serialize(book).should be == {
          'title' => book.title,
          'authors' => [
            {
              '__metadata__' => {
                'class' => 'User',
                'id' => dave.id
              }
            },
            {
              '__metadata__' => {
                'class' => 'User',
                'id' => andy.id
              }
            }
          ]
        }
      end

      context 'with objects that have hashes as attributes' do
        let(:name_data) { {first_name: 'Jamie', last_name: 'Gaskins'} }
        let(:serialized_data) do
          {
            'name' => name_data
          }
        end
        let(:user) { User.new(name_data) }
        let(:user_mapper) { mapper_registry[User] }
        let(:user_serializer) { Serializer.new(user_mapper) }

        before do
          data_source.stub(:can_serialize?).with(name_data) { true }
        end

        it 'serializes' do
          user_serializer.serialize(user).should be == serialized_data
        end

        it 'unserializes' do
          user_serializer.unserialize(serialized_data).name.should be == user.name
        end
      end

      describe 'unserializes attributes' do
        let(:unserializable_object) { 1.to_c }
        let(:serialized_attrs) { [ Marshal.dump(unserializable_object) ] }
        let(:objects) { serializer.unserialize(serialized_attrs)  }
        subject { objects.first }

        it { should be_a Complex }
        it { should eq unserializable_object}
      end

      describe 'with an array of references' do
        let(:author) { Reference.new(User, 1) }
        let(:title) { 'title' }
        let(:book) { Book.new(title, [author]) }

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
    end
  end
end
