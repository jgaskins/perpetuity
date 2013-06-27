require 'perpetuity/postgres'

module Perpetuity
  describe Postgres do
    let(:postgres) { Postgres.new }

    it 'creates SQL queries with a block' do
      postgres.query(Object) { |o| o.name == 'foo' }.to_db.should ==
        "SELECT * FROM Object WHERE name = 'foo'"
    end
  end
end
