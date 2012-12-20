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
      connection = double('connection')
      Mongo::Connection.stub(new: connection)
      mongo.connect
      mongo.should be_connected
      mongo.connection.should == connection
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

    it 'uses the selected database' do
      mongo.database.name.should == 'perpetuity_gem_test'
    end

    it 'removes all documents from a collection' do
      mongo.insert klass, {}
      mongo.delete_all klass
      mongo.count(klass).should == 0
    end

    it 'counts the documents in a collection' do
      mongo.delete_all klass
      3.times do
        mongo.insert klass, {}
      end
      mongo.count(klass).should == 3
    end

    it 'gets the first document in a collection' do
      value = {value: 1}
      mongo.insert klass, value
      mongo.first(klass)[:hypothetical_value].should == value['value']
    end

    it 'gets all of the documents in a collection' do
      values = [{value: 1}, {value: 2}]
      mongo.should_receive(:retrieve).with(Object, {}, {})
           .and_return(values)
      mongo.all(Object).should == values
    end

    it 'retrieves by id if the id is a string' do
      time = Time.now.utc
      id = mongo.insert Object, {inserted: time}
      objects = mongo.retrieve(Object, id: id.to_s).to_a
      objects.map{|i| i["inserted"].to_f}.first.should be_within(0.001).of time.to_f
    end

    describe 'serializable objects' do
      let(:serializable_values) { [nil, true, false, 1, 1.2, '', [], {}, Time.now] }

      it 'can insert serializable values' do
        serializable_values.each do |value|
          mongo.insert(Object, {value: value}).should be_a BSON::ObjectId
          mongo.can_serialize?(value).should be_true
        end
      end
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
    end
  end
end
