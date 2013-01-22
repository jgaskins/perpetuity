require 'perpetuity/serializer'
require 'perpetuity/mapper'
require 'perpetuity/mapper_registry'
require 'support/test_classes/book'
require 'support/test_classes/user'

module Perpetuity
  describe Serializer do
    let(:dave) { User.new('Dave') }
    let(:andy) { User.new('Andy') }
    let(:authors) { [dave, andy] }
    let(:book) { Book.new('The Pragmatic Programmer', authors) }
    let(:mapper_registry) { MapperRegistry.new }
    let!(:book_mapper) do
      registry = mapper_registry
      Class.new(Perpetuity::Mapper) do
        map Book, registry
        attribute :title
        attribute :authors
      end
    end
    let!(:user_mapper) do
      registry = mapper_registry
      Class.new(Perpetuity::Mapper) do
        map User, registry
        attribute :name
      end
    end
    let(:data_source) { double('Data Source') }
    let(:serializer) { Serializer.new(mapper_registry[Book], mapper_registry) }

    before do
      dave.stub(id: 1)
      andy.stub(id: 2)
      user_mapper.stub(data_source: data_source)
      book_mapper.stub(data_source: data_source)
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
  end
end
