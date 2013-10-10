require 'perpetuity/postgres/table'
require 'perpetuity/postgres/table/attribute'

module Perpetuity
  class Postgres
    describe Table do
      let(:title)  { Table::Attribute.new('title', String, max_length: 40) }
      let(:body)   { Table::Attribute.new('body', String) }
      let(:author) { Table::Attribute.new('author', Object) }
      let(:published_at) { Table::Attribute.new('published_at', Time) }
      let(:attributes) { [title, body, author, published_at] }
      let(:table) { Table.new('Article', attributes) }

      it 'knows its name' do
        table.name.should == 'Article'
      end

      it 'knows its attributes' do
        table.attributes.should == attributes
      end

      it 'generates proper SQL to create itself' do
        table.create_table_sql.should ==
          'CREATE TABLE IF NOT EXISTS "Article" (id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), title VARCHAR(40), body TEXT, author JSON, published_at DATETIME)'
      end
    end
  end
end
