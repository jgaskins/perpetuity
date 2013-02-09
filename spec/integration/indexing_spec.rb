require 'spec_helper'

describe 'indexing' do
  let(:mapper_class) do
    Class.new(Perpetuity::Mapper) do
      map Object
      attribute :name
      index :name, unique: true
    end
  end
  let(:mapper) { mapper_class.new }
  let(:name_index) do
    mapper.indexes.find do |index|
      index.attribute.to_s == :name
    end
  end

  after { mapper.data_source.drop_collection Object }

  it 'adds indexes to database collections/tables' do
    name_index.attribute.name.should be == :name
  end

  it 'verifies that indexes are inactive' do
    name_index.should be_inactive
  end

  it 'creates indexes' do
    mapper.reindex!
    name_index.should be_active
    mapper.remove_index! name_index
  end

  it 'specifies uniqueness of the index' do
    name_index.should be_unique
  end
end

