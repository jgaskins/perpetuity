require 'perpetuity/mongodb/query_expression'

module Perpetuity
  describe MongoDB::QueryExpression do
    let(:expression) { MongoDB::QueryExpression.new :attribute, :equals, :value }
    subject { expression }

    describe 'translation to Mongo expressions' do
      it 'equality expression' do
        expression.to_db.should == { attribute: :value }
      end

      it 'less-than expression' do
        expression.comparator = :less_than
        expression.to_db.should == { attribute: { '$lt' => :value } }
      end

      it 'less-than-or-equal-to expression' do
        expression.comparator = :lte
        expression.to_db.should == { attribute: { '$lte' => :value } }
      end

      it 'greater-than expression' do
        expression.comparator = :greater_than
        expression.to_db.should == { attribute: { '$gt' => :value } }
      end

      it 'greater-than-or-equal-to expression' do
        expression.comparator = :gte
        expression.to_db.should == { attribute: { '$gte' => :value } }
      end

      it 'not-equal' do
        expression.comparator = :not_equal
        expression.to_db.should == { attribute: { '$ne' => :value } }
      end

      it 'checks for inclusion' do
        expression.comparator = :in
        expression.to_db.should == { attribute: { '$in' => :value } }
      end

      it 'checks for regexp matching' do
        expression.comparator = :matches
        expression.to_db.should == { attribute: :value }
      end
    end

    describe 'unions' do
      let(:lhs) { MongoDB::QueryExpression.new :first, :equals, :one }
      let(:rhs) { MongoDB::QueryExpression.new :second, :equals, :two }

      it 'converts | to an $or query' do
        (lhs | rhs).to_db.should == { '$or' => [{first: :one}, {second: :two}] }
      end
    end

    describe 'intersections' do
      let(:lhs) { MongoDB::QueryExpression.new :first, :equals, :one }
      let(:rhs) { MongoDB::QueryExpression.new :second, :equals, :two }

      it 'converts & to an $and query' do
        (lhs & rhs).to_db.should == { '$and' => [{first: :one}, {second: :two}] }
      end
    end
  end
end
