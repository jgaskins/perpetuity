require 'perpetuity/mongodb/query_union'
require 'perpetuity/mongodb/query_expression'

module Perpetuity
  class MongoDB
    describe QueryUnion do
      let(:lhs) { QueryExpression.new :first, :equals, 'one' }
      let(:rhs) { QueryExpression.new :second, :equals, 'two' }
      let(:union) { QueryUnion.new lhs, rhs }

      it 'returns the proper union of two expressions' do
        union.to_db.should be == { '$or' => [{first: 'one'}, {second: 'two'}] }
      end
    end
  end
end
