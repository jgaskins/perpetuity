require 'perpetuity/mapper_registry'
require 'perpetuity/mapper'
require 'perpetuity/mongodb'

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

    describe 'talking to the data source' do
      let(:data_source) { MongoDB.new(db: nil) }
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

      describe 'finding a single object' do
        let(:options) { {:attribute=>nil, :direction=>nil, :limit=>nil, :page=>nil} }
        let(:returned_object) { double('Retrieved Object', id: 1, class: Object) }

        it 'finds an object by ID' do
          criteria = { id: 1 }
          data_source.should_receive(:retrieve)
                     .with(Object, criteria, options) { [returned_object] }

          mapper.find(1).should be == returned_object
        end

        it 'finds multiple objects with a block' do
          criteria = { name: 'foo' }
          data_source.should_receive(:retrieve)
                     .with(Object, criteria, options) { [returned_object] }.twice

          mapper.select   { |e| e.name == 'foo' }.to_a.should == [returned_object]
          mapper.find_all { |e| e.name == 'foo' }.to_a.should == [returned_object]
        end

        it 'finds an object with a block' do
          criteria = { name: 'foo' }
          data_source.should_receive(:retrieve)
                     .with(Object, criteria, options) { [returned_object] }.twice
          mapper.find   { |o| o.name == 'foo' }.should == returned_object
          mapper.detect { |o| o.name == 'foo' }.should == returned_object
        end

        it 'caches results' do
          criteria = { id: 1 }
          data_source.should_receive(:retrieve)
                     .with(Object, criteria, options) { [returned_object] }
                     .once

          mapper.find(1)
          mapper.find(1)
        end

        it 'does not cache nil results' do
          criteria = { id: 1 }
          data_source.should_receive(:retrieve)
                     .with(Object, criteria, options) { [] }
                     .twice

          mapper.find(1)
          mapper.find(1)
        end
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
