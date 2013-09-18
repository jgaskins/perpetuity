require 'perpetuity/postgres/table'
require 'perpetuity/postgres/table/attribute'

module Perpetuity
  class Postgres
    describe Table do
      let(:title)  { Table::Attribute.new('title', String, max_length: 40) }
      let(:body)   { Table::Attribute.new('body', String) }
      let(:author) { Table::Attribute.new('author', Object) }
      let(:attributes) { [title, body, author] }
      let(:table) { Table.new('Article', attributes) }

      it 'knows its name' do
        table.name.should == 'Article'
      end

      it 'knows its attributes' do
        table.attributes.should == attributes
      end

      it 'generates proper SQL to create itself' do
        table.create_table_sql.should ==
          'CREATE TABLE Article (title VARCHAR(40), body TEXT, author JSON)'
      end
    end
  end
end
