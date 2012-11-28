require 'perpetuity/mongodb/query_intersection'
require 'perpetuity/mongodb/query_expression'

module Perpetuity
  class MongoDB
    describe QueryIntersection do
      let(:lhs) { QueryExpression.new :first, :equals, 'one' }
      let(:rhs) { QueryExpression.new :second, :equals, 'two' }
      let(:intersection) { QueryIntersection.new lhs, rhs }

      it 'returns a Mongo representation of the union of 2 expressions' do
        intersection.to_db.should be == { '$and' => [{first: 'one'}, {second: 'two'}] }
      end
    end
  end
end
