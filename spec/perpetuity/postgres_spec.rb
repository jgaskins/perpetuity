require 'perpetuity/postgres'
require 'perpetuity/postgres/table/attribute'
require 'perpetuity/attribute'

module Perpetuity
  describe Postgres do
    let(:postgres) { Postgres.new(db: 'perpetuity_gem_test') }

    describe 'initialization params' do
      context 'with params' do
        let(:host)      { double('host') }
        let(:port)      { double('port') }
        let(:db)        { double('db') }
        let(:pool_size) { double('pool size') }
        let(:username)  { double('username') }
        let(:password)  { double('password') }
        let(:postgres) do
          Postgres.new(
            host:      host,
            port:      port,
            db:        db,
            pool_size: pool_size,
            username:  username,
            password:  password
          )
        end
        subject { postgres }

        its(:host)      { should == host }
        its(:port)      { should == port }
        its(:db)        { should == db }
        its(:pool_size) { should == pool_size }
        its(:username)  { should == username }
        its(:password)  { should == password }
      end

      context 'default values' do
        let(:postgres) { Postgres.new(db: 'my_db') }
        subject { postgres }

        its(:host)      { should == 'localhost' }
        its(:port)      { should == 5432 }
        its(:pool_size) { should == 5 }
        its(:username)  { should == ENV['USER'] }
        its(:password)  { should be_nil }
      end
    end

    it 'creates and drops tables' do
      postgres.create_table 'Article', [
        Postgres::Table::Attribute.new('title', String, max_length: 40),
        Postgres::Table::Attribute.new('body', String),
        Postgres::Table::Attribute.new('author', Object)
      ]
      postgres.should have_table('Article')

      postgres.drop_table 'Article'
      postgres.should_not have_table 'Article'
    end

    it 'converts values into something that works with the DB' do
      postgres.postgresify("string").should == "'string'"
      postgres.postgresify(1).should == 1
      postgres.postgresify(true).should == 'TRUE'
    end

    describe 'working with data' do
      let(:attributes) { [Attribute.new(:name, String)] }
      let(:data) { ["('Jamie')"] }

      it 'inserts data and finds by id' do
        id = postgres.insert 'User', data, attributes
        result = postgres.find('User', id)

        id.should =~ /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/
        result['name'].should == 'Jamie'
      end

      it 'counts objects' do
        expect { postgres.insert 'User', data, attributes }.to change { postgres.count('User') }.by 1
      end

      it 'returns a count of 0 when the table does not exist' do
        postgres.drop_table 'Article'
        postgres.count('Article').should == 0
      end

      it 'deletes all records' do
        postgres.insert 'User', data, attributes
        postgres.delete_all 'User'
        postgres.count('User').should == 0
      end
    end

    describe 'query generation' do
      it 'creates SQL queries with a block' do
        postgres.query(Object) { |o| o.name == 'foo' }.to_db.should ==
          "SELECT * FROM Object WHERE name = 'foo'"
      end

      it 'does not allow SQL injection' do
        query = postgres.query(Object) { |o| o.name == "' OR 1; --" }.to_db
        query.should == "SELECT * FROM Object WHERE name = '\\' OR 1; --'"
      end
    end
  end
end
