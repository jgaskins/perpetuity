require 'perpetuity/postgres/query_intersection'

module Perpetuity
  class Postgres
    describe QueryIntersection do
      let(:lhs) { double('LHS', to_db: 'left = 1') }
      let(:rhs) { double('RHS', to_db: 'right = 2') }
      let(:intersection) { QueryIntersection.new(lhs, rhs) }

      it 'converts to a SQL "AND" expression' do
        intersection.to_db.should == '(left = 1 AND right = 2)'
      end

      it 'allows intersections to have other intersections' do
        (intersection&intersection).to_db.should == '((left = 1 AND right = 2) AND (left = 1 AND right = 2))'
      end

      it 'allows intersections to have unions' do
        (intersection|intersection).to_db.should == '((left = 1 AND right = 2) OR (left = 1 AND right = 2))'
      end
    end
  end
end
