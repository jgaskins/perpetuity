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
      expect(mapper_class.attributes).to eq [:name]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      expect(mapper_class.attributes).to be_empty
    end

    it 'can have embedded attributes' do
      mapper_class.attribute :comments, embedded: true
      expect(mapper_class.attribute_set[:comments]).to be_embedded
    end

    it 'registers itself with the mapper registry' do
      mapper_class.map Object, registry
      expect(registry[Object]).to be_instance_of mapper_class
    end

    describe 'talking to the data source' do
      let(:data_source) { MongoDB.new(db: nil) }
      before do
        allow(mapper_class).to receive(:data_source) { data_source }
        mapper_class.map Object, registry
      end

      specify 'mappers use the data source that the mapper class uses' do
        expect(mapper.data_source).to be data_source
      end

      it 'inserts objects into a data source' do
        mapper_class.attribute :my_attribute
        obj = Object.new
        obj.instance_variable_set '@my_attribute', 'foo'
        expect(data_source).to receive(:can_serialize?).with('foo') { true }
        expect(data_source).to receive(:insert)
                   .with('Object', [{ 'my_attribute' => 'foo' }], mapper.attribute_set)
                   .and_return(['bar'])

        expect(mapper.insert(obj)).to be == 'bar'
      end

      it 'counts objects of its mapped class in the data source' do
        expect(data_source).to receive(:count).with('Object') { 4 }
        expect(mapper.count).to be == 4
      end

      describe 'finding specific objects' do
        let(:options) { {:attribute=>nil, :direction=>nil, :limit=>1, :skip=>nil} }
        let(:returned_object) { double('Retrieved Object', class: Object, delete: nil) }

        it 'finds an object by ID' do
          returned_object.instance_variable_set :@id, 1
          criteria = data_source.query { |o| o.id == 1 }
          expect(data_source).to receive(:retrieve)
                     .with('Object', criteria, options) { [returned_object] }

          expect(mapper.find(1)).to be == returned_object
        end

        it 'finds multiple objects by ID' do
          first, second = double, double
          mapper.give_id_to first, 1
          mapper.give_id_to second, 2
          criteria = data_source.query { |o| o.id.in [1, 2] }
          options.merge! limit: nil
          expect(data_source).to receive(:retrieve)
                     .with('Object', criteria, options)
                     .and_return [first, second]

          expect(mapper.find([1, 2]).to_a).to be == [first, second]
        end

        it 'finds multiple objects with a block' do
          criteria = data_source.query { |o| o.name == 'foo' }
          options = self.options.merge(limit: nil)
          expect(data_source).to receive(:retrieve)
                     .with('Object', criteria, options) { [returned_object] }.twice

          expect(mapper.select   { |e| e.name == 'foo' }.to_a).to be == [returned_object]
          expect(mapper.find_all { |e| e.name == 'foo' }.to_a).to be == [returned_object]
        end

        it 'finds an object with a block' do
          criteria = data_source.query { |o| o.name == 'foo' }
          expect(data_source).to receive(:retrieve)
                     .with('Object', criteria, options) { [returned_object] }.twice
          expect(mapper.find   { |o| o.name == 'foo' }).to be == returned_object
          expect(mapper.detect { |o| o.name == 'foo' }).to be == returned_object
        end

        it 'caches results' do
          mapper.give_id_to returned_object, 1
          criteria = data_source.query { |o| o.id == 1 }
          duplicate = returned_object.dup
          allow(duplicate).to receive(:class) { returned_object.class }
          allow(returned_object).to receive(:dup) { duplicate }
          expect(data_source).to receive(:retrieve)
                     .with('Object', criteria, options) { [returned_object] }
                     .once

          mapper.find(1)
          mapper.find(1)
        end

        it 'does not cache nil results' do
          criteria = data_source.query { |o| o.id == 1 }
          expect(data_source).to receive(:retrieve)
                     .with('Object', criteria, options) { [] }
                     .twice

          mapper.find(1)
          mapper.find(1)
        end
      end

      it 'saves an object' do
        mapper_class.attribute :foo
        object = Object.new
        mapper.give_id_to object, 1
        object.instance_variable_set '@foo', 'bar'
        expect(data_source).to receive(:can_serialize?).with('bar') { true }
        expect(data_source).to receive(:update).with 'Object', 1, { 'foo' => 'bar' }

        mapper.save object
      end

      it 'can serialize only changed attributes for updates' do
        mapper_class.attribute :modified
        mapper_class.attribute :unmodified
        object = Object.new
        object.instance_variable_set :@id, 1
        object.instance_variable_set :@modified, false
        object.instance_variable_set :@unmodified, false
        mapper.dirty_tracker << object

        object.instance_variable_set :@modified, true

        expect(mapper.serialize_changed_attributes(object)).to be == {
          'modified' => true
        }
      end

      it 'deletes an object from the data source' do
        object = Object.new

        expect(data_source).to receive(:delete).with [object], 'Object'
        mapper.delete object
      end

      it 'deletes all objects it manages' do
        expect(data_source).to receive(:delete_all).with('Object')
        mapper.delete_all
      end
    end

    describe 'checking persistence of an object' do
      let(:object) { Object.new }

      context 'when persisted' do
        before { mapper.give_id_to object, 1 }

        it 'knows the object is persisted' do
          expect(mapper.persisted?(object)).to be_truthy
        end

        it 'knows the id of the object' do
          expect(mapper.id_for(object)).to be == 1
        end
      end

      context 'when not persisted' do
        it 'knows the object is not persisted' do
          expect(mapper.persisted?(object)).to be_falsey
        end

        it 'returns a nil id' do
          expect(mapper.id_for(object)).to be_nil
        end
      end
    end

    describe 'setting the id manually' do
      context 'when setting the type' do
        it 'adds the attribute to the attribute set' do
          mapper_class.id(String) { 1.to_s }
          id_attr = mapper_class.attribute_set[:id]
          expect(id_attr.type).to be String
        end
      end

      context 'when not setting the type' do
        it 'does not add the attribute' do
          mapper_class.id { 1.to_s }
          expect(mapper_class.attribute_set[:id]).to be_nil
        end
      end
    end

    describe 'using an existing identity map' do
      it 'is initialized with an existing map' do
        registry = Object.new
        id_map = Object.new
        mapper = Mapper.new(registry, id_map)
        expect(mapper.identity_map).to be id_map
      end
    end

    describe 'specifying the collection/table name' do
      it 'changes the collection name' do
        mapper_class.collection_name = 'articles'
        expect(mapper.collection_name).to be == 'articles'
      end

      it 'defaults to the mapped class name' do
        mapper_class.map Object
        expect(mapper.collection_name).to be == 'Object'
      end
    end
  end
end
