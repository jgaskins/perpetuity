$:.unshift('lib').uniq!
require 'perpetuity/mongodb'

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
  end
end
