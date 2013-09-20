require 'perpetuity/postgres/expression'

module Perpetuity
  class Postgres
    describe Expression do
      let(:expression) { Expression.new('uuid_generate_v4()') }

      it 'passes the expression straight into SQL' do
        expression.to_sql.should == 'uuid_generate_v4()'
      end
    end
  end
end
