require 'perpetuity/mapper_registry'
require 'perpetuity/mapper'

module Perpetuity
  describe Mapper do
    let(:registry) { MapperRegistry.new}
    let(:mapper_class) { Class.new(Mapper) }
    let(:mapper) { mapper_class.new(registry) }
    subject { mapper }

    it { should be_a Mapper }

    it 'has correct attributes' do
      mapper_class.attribute :name
      mapper_class.attributes.should eq [:name]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      mapper_class.attributes.should be_empty
    end

    it 'can have embedded attributes' do
      mapper_class.attribute :comments, embedded: true
      mapper_class.attribute_set[:comments].should be_embedded
    end

    it 'registers itself with the mapper registry' do
      mapper_class.map Object, registry
      registry[Object].should be_instance_of mapper_class
    end

    context 'with unserializable embedded attributes' do
      let(:unserializable_object) { 1.to_c }
      let(:serialized_attrs) do
        [ Marshal.dump(unserializable_object) ]
      end

      it 'serializes attributes' do
        object = Object.new
        object.instance_variable_set '@sub_objects', [unserializable_object]
        mapper_class.attribute :sub_objects, embedded: true
        mapper_class.map Object, registry
        data_source = double(:data_source)
        mapper.stub(data_source: data_source)
        data_source.should_receive(:can_serialize?).with(unserializable_object).and_return false

        mapper.serialize(object)['sub_objects'].should eq serialized_attrs
      end
    end

    describe 'talking to the data source' do
      let(:data_source) { double }
      before do
        mapper_class.stub(data_source: data_source)
        mapper_class.map Object, registry
      end

      specify 'mappers use the data source that the mapper class uses' do
        mapper.data_source.should be data_source
      end

      it 'inserts objects into a data source' do
        mapper_class.attribute :my_attribute
        obj = Object.new
        obj.instance_variable_set '@my_attribute', 'foo'
        data_source.should_receive(:can_serialize?).with('foo') { true }
        data_source.should_receive(:insert)
                   .with(Object,
                         { 'my_attribute' => 'foo' })
                   .and_return('bar')

        mapper.insert(obj).should be == 'bar'
      end

      it 'counts objects of its mapped class in the data source' do
        data_source.should_receive(:count).with(Object) { 4 }
        mapper.count.should be == 4
      end

      it 'finds an object by ID' do
        returned_object = double('Retrieved Object')
        criteria = { id: 1 }
        options = {:attribute=>nil, :direction=>nil, :limit=>nil, :page=>nil}
        data_source.should_receive(:retrieve)
                   .with(Object, criteria, options) { [returned_object] }

        mapper.find(1).should be == returned_object
      end

      it 'saves an object' do
        mapper_class.attribute :foo
        object = Object.new
        object.define_singleton_method(:id) { 1 }
        object.instance_variable_set '@foo', 'bar'
        data_source.should_receive(:can_serialize?).with('bar') { true }
        data_source.should_receive(:update).with Object, 1, { 'foo' => 'bar' }

        mapper.save object
      end

      it 'deletes an object from the data source' do
        object = Object.new

        data_source.should_receive(:delete).with object, Object
        mapper.delete object
      end

      it 'deletes all objects it manages' do
        data_source.should_receive(:delete_all).with(Object)
        mapper.delete_all
      end
    end
  end
end
