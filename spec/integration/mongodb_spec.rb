require 'perpetuity/mongodb'
require 'date'

module Perpetuity
  describe MongoDB do
    let(:mongo) { MongoDB.new db: 'perpetuity_gem_test' }
    let(:klass) { String }
    subject { mongo }

    it 'is not connected when instantiated' do
      mongo.should_not be_connected
    end

    it 'connects to its host' do
      mongo.connect
      mongo.should be_connected
    end

    it 'connects automatically when accessing the database' do
      mongo.database
      mongo.should be_connected
    end

    describe 'initialization params' do
      let(:host)      { double('host') }
      let(:port)      { double('port') }
      let(:db)        { double('db') }
      let(:pool_size) { double('pool size') }
      let(:username)  { double('username') }
      let(:password)  { double('password') }
      let(:mongo) do
        MongoDB.new(
          host:      host,
          port:      port,
          db:        db,
          pool_size: pool_size,
          username:  username,
          password:  password
        )
      end
      subject { mongo }

      its(:host)      { should == host }
      its(:port)      { should == port }
      its(:db)        { should == db }
      its(:pool_size) { should == pool_size }
      its(:username)  { should == username }
      its(:password)  { should == password }
    end

    it 'inserts documents into a collection' do
      expect { mongo.insert klass, { name: 'foo' }, [] }.to change { mongo.count klass }.by 1
    end

    it 'inserts multiple documents into a collection' do
      expect { mongo.insert klass, [{name: 'foo'}, {name: 'bar'}], [] }
        .to change { mongo.count klass }.by 2
    end

    it 'removes all documents from a collection' do
      mongo.insert klass, {}, []
      mongo.delete_all klass
      mongo.count(klass).should == 0
    end

    it 'counts the documents in a collection' do
      mongo.delete_all klass
      3.times do
        mongo.insert klass, {}, []
      end
      mongo.count(klass).should == 3
    end

    it 'counts the documents matching a query' do
      mongo.delete_all klass
      1.times { mongo.insert klass, { name: 'bar' }, [] }
      3.times { mongo.insert klass, { name: 'foo' }, [] }
      mongo.count(klass) { |o| o.name == 'foo' }.should == 3
    end

    it 'gets the first document in a collection' do
      value = {value: 1}
      mongo.insert klass, value, []
      mongo.first(klass)[:hypothetical_value].should == value['value']
    end

    it 'gets all of the documents in a collection' do
      values = [{value: 1}, {value: 2}]
      mongo.should_receive(:retrieve).with(Object, mongo.nil_query, {})
           .and_return(values)
      mongo.all(Object).should == values
    end

    it 'retrieves by id if the id is a string' do
      time = Time.now.utc
      id = mongo.insert Object, {inserted: time}, []

      object = mongo.retrieve(Object, mongo.query{|o| o.id == id.to_s }).first
      retrieved_time = object["inserted"]
      retrieved_time.to_f.should be_within(0.001).of time.to_f
    end

    describe 'serialization' do
      let(:object) { Object.new }
      let(:foo_attribute) { double('Attribute', name: :foo) }
      let(:baz_attribute) { double('Attribute', name: :baz) }
      let(:mapper) { double('Mapper',
                            mapped_class: Object,
                            mapper_registry: {},
                            attribute_set: Set[foo_attribute, baz_attribute],
                            data_source: mongo,
                           ) }

      before do
        object.instance_variable_set :@foo, 'bar'
        object.instance_variable_set :@baz, 'quux'
      end

      it 'serializes objects' do
        mongo.serialize(object, mapper).should == {
          'foo' => 'bar',
          'baz' => 'quux'
        }
      end

      it 'can serialize only modified attributes of objects' do
        updated = object.dup
        updated.instance_variable_set :@foo, 'foo'

        serialized = mongo.serialize_changed_attributes(updated, object, mapper)
        serialized.should == { 'foo' => 'foo' }
      end
    end

    describe 'serializable objects' do
      let(:serializable_values) { [nil, true, false, 1, 1.2, '', [], {}, Time.now] }

      it 'can insert serializable values' do
        serializable_values.each do |value|
          mongo.insert(Object, {value: value}, []).should be_a Moped::BSON::ObjectId
          mongo.can_serialize?(value).should be_true
        end
      end
    end

    it 'generates a new query DSL object' do
      mongo.query { |object| object.whatever == 1 }.should respond_to :to_db
    end

    describe 'indexing' do
      let(:collection) { Object }
      let(:key) { 'object_id' }

      before { mongo.index collection, key }
      after { mongo.drop_collection collection }

      it 'adds indexes for the specified key on the specified collection' do
        indexes = mongo.indexes(collection).select{ |index| index.attribute == 'object_id' }
        indexes.should_not be_empty
        indexes.first.order.should be :ascending
      end

      it 'adds descending-order indexes' do
        index = mongo.index collection, 'hash', order: :descending
        index.order.should be :descending
      end

      it 'creates indexes on the database collection' do
        mongo.delete_all collection
        index = mongo.index collection, 'real_index', order: :descending, unique: true
        mongo.activate_index! index

        mongo.active_indexes(collection).should include index
      end

      it 'removes indexes' do
        mongo.drop_collection collection
        index = mongo.index collection, 'real_index', order: :descending, unique: true
        mongo.activate_index! index
        mongo.remove_index index
        mongo.active_indexes(collection).should_not include index
      end
    end

    describe 'atomic operations' do
      after(:all) { mongo.delete_all klass }

      it 'increments the value of an attribute' do
        id = mongo.insert klass, { count: 1 }, []
        mongo.increment klass, id, :count
        mongo.increment klass, id, :count, 10
        query = mongo.query { |o| o.id == id }
        mongo.retrieve(klass, query).first['count'].should be == 12
        mongo.increment klass, id, :count, -1
        mongo.retrieve(klass, query).first['count'].should be == 11
      end
    end

    describe 'operation errors' do
      let(:data) { { foo: 'bar' } }
      let(:index) { mongo.index Object, :foo, unique: true }

      before do
        mongo.delete_all Object
        mongo.activate_index! index
      end

      after { mongo.drop_collection Object }

      it 'raises an exception when insertion fails' do
        mongo.insert Object, data, []

        expect { mongo.insert Object, data, [] }.to raise_error DuplicateKeyError,
          'Tried to insert Object with duplicate unique index: foo => "bar"'
      end
    end
  end
end
