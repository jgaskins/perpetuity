require 'perpetuity/postgres/table/attribute'

module Perpetuity
  class Postgres
    class Table
      describe Attribute do
        let(:title)  { Table::Attribute.new('title', String, max_length: 40) }

        it 'knows its name' do
          title.name.should == 'title'
        end

        it 'knows its type' do
          title.type.should == String
        end

        describe 'strings' do
          let(:body) { Table::Attribute.new('body', String) }

          it 'converts to the proper SQL type' do
            title.sql_type.should == 'VARCHAR(40)'
            body.sql_type.should == 'TEXT'
          end
        end

        describe 'non-serializable types' do
          let(:author) { Table::Attribute.new('author', Object) }

          it 'has an SQL type of JSON' do
            author.sql_type.should == 'JSON'
          end
        end
      end
    end
  end
end
