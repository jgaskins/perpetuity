require 'perpetuity/postgres/connection'

module Perpetuity
  class Postgres
    describe Connection do
      let(:connection) { Connection.new(db: 'perpetuity_gem_test') }

      it 'sanitizes the options for the pg gem' do
        options = { db: 'db', username: 'user' }
        connection.sanitize_options(options).should == {
          dbname: 'db',
          user: 'user'
        }
      end

      it 'is only activated when it is used' do
        connection.should_not be_active
        connection.connect
        connection.should be_active
      end

      it 'executes SQL' do
        connection.execute 'CREATE TABLE IF NOT EXISTS abcdefg (name text)'
        connection.tables.should include 'abcdefg'
        connection.execute 'DROP TABLE IF EXISTS abcdefg'
        connection.tables.should_not include 'abcdefg'
      end
    end
  end
end
