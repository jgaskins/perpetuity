require 'spec_helper'

describe 'indexing' do
  let(:mapper_class) do
    Class.new(Perpetuity::Mapper) do
      map Object
      attribute :name
      index :name, unique: true
    end
  end
  let(:mapper_class_without_index) do
    klass = mapper_class.dup
    klass.new.indexes.reject! do |index|
      index.attribute.name == :name
    end
    klass
  end
  let(:mapper) { mapper_class.new }
  let(:name_index) do
    mapper.indexes.find do |index|
      index.attribute.to_s == :name
    end
  end
  let(:db_name) { Perpetuity.configuration.data_source.db }

  before do
    Perpetuity.data_source :mongodb, db_name
    mapper.data_source.drop_collection Object
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

  it 'removes other indexes' do
    mapper.reindex!
    mapper_without_index = mapper_class_without_index.new
    mapper_without_index.reindex!
    mapper.data_source.active_indexes(Object).any? do |index|
      index.attribute.name.to_s == 'name'
    end.should be_false
  end
end

