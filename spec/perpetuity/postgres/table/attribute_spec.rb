require 'perpetuity/postgres/table/attribute'
require 'perpetuity/postgres/expression'

module Perpetuity
  class Postgres
    class Table
      describe Attribute do
        let(:title)  { Attribute.new('title', String, max_length: 40) }

        it 'knows its name' do
          title.name.should == 'title'
        end

        it 'knows its type' do
          title.type.should == String
        end

        describe 'id' do
          let(:id) do
            Attribute.new('id', Attribute::UUID,
                          primary_key: true,
                          default: Expression.new('uuid_generate_v4()')
                         )
          end

          it 'is a UUID type' do
            id.sql_type.should == 'UUID'
          end

          it 'is a primary key' do
            id.should be_primary_key
          end

          it 'can have a specified default' do
            id.default.should == Expression.new('uuid_generate_v4()')
          end

          it 'generates the proper SQL' do
            id.sql_declaration.should == 'id UUID PRIMARY KEY DEFAULT uuid_generate_v4()'
          end
        end

        describe 'strings' do
          let(:body) { Attribute.new('body', String, default: 'foo') }

          it 'converts to the proper SQL type' do
            title.sql_type.should == 'VARCHAR(40)'
            body.sql_type.should == 'TEXT'
          end

          it 'generates the proper SQL' do
            body.sql_declaration.should == "body TEXT DEFAULT 'foo'"
          end
        end

        describe 'times' do
          let(:timestamp) { Attribute.new('timestamp', Time) }

          it 'converts to the SQL DATETIME type' do
            timestamp.sql_type.should == 'DATETIME'
          end
        end

        describe 'non-serializable types' do
          let(:author) { Attribute.new('author', Object) }

          it 'has an SQL type of JSON' do
            author.sql_type.should == 'JSON'
          end
        end
      end
    end
  end
end
