require 'perpetuity/postgres/query_union'

module Perpetuity
  class Postgres
    describe QueryUnion do
      let(:lhs) { double('LHS', to_db: 'left = 1') }
      let(:rhs) { double('RHS', to_db: 'right = 2') }
      let(:union) { QueryUnion.new(lhs, rhs) }

      it 'converts to a SQL "OR" expression' do
        union.to_db.should == '(left = 1 OR right = 2)'
      end

      it 'allows unions to have other unions' do
        (union|union).to_db.should == '((left = 1 OR right = 2) OR (left = 1 OR right = 2))'
      end

      it 'allows unions to have intersections' do
        (union&union).to_db.should == '((left = 1 OR right = 2) AND (left = 1 OR right = 2))'
      end
    end
  end
end
