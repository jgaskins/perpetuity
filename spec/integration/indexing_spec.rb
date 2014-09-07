require 'spec_helper'

describe 'indexing' do
  let(:mapper_class) do
    Class.new(Perpetuity::Mapper) do
      map Object
      attribute :name, type: String
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
      index.attribute.name == :name
    end
  end
  let(:db_name) { Perpetuity.configuration.data_source.db }

  before do
    load './spec/spec_helper.rb'
    mapper.data_source.drop_collection Object
  end
  after { mapper.data_source.drop_collection Object }

  it 'adds indexes to database collections/tables' do
    expect(name_index.attribute.name).to be == :name
  end

  it 'verifies that indexes are inactive' do
    expect(name_index).to be_inactive
  end

  it 'creates indexes' do
    mapper.reindex!
    index_names = mapper.data_source.active_indexes(Object).map do |index|
      index.attribute.name.to_s
    end
    expect(index_names).to include 'name'
    expect(name_index).to be_active
  end

  it 'specifies uniqueness of the index' do
    expect(name_index).to be_unique
  end

  it 'removes other indexes' do
    mapper.reindex!
    mapper_without_index = mapper_class_without_index.new
    mapper_without_index.reindex!
    any_indexes = mapper.data_source.active_indexes(Object).any? do |index|
      index.attribute.name.to_s == 'name'
    end

    expect(any_indexes).to be_falsey
  end
end

