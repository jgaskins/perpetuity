require 'perpetuity/postgres/query_expression'

module Perpetuity
  class Postgres
    describe QueryExpression do
      let(:expression) { QueryExpression.new :attribute, :==, :value }
      subject { expression }

      describe 'translation to SQL expressions' do
        it 'translates equality to symbol by comparing with a string' do
          expression.to_db.should == "attribute = 'value'"
        end

        it 'translates equality to strings' do
          expression.value = expression.value.to_s
          expression.to_db.should == "attribute = 'value'"
        end

        it 'removes SQL injection from strings' do
          expression.value = "' OR 1; --"
          expression.to_db.should == "attribute = '\\' OR 1; --'"
        end

        it 'translates equality to numbers' do
          expression.value = 1
          expression.to_db.should == 'attribute = 1'
        end

        it 'less-than expression' do
          expression.comparator = :<
          expression.to_db.should == "attribute < 'value'"
        end

        it 'less-than-or-equal-to expression' do
          expression.comparator = :<=
          expression.to_db.should == "attribute <= 'value'"
        end

        it 'greater-than expression' do
          expression.comparator = :>
          expression.to_db.should == "attribute > 'value'"
        end

        it 'greater-than-or-equal-to expression' do
          expression.comparator = :>=
          expression.to_db.should == "attribute >= 'value'"
        end

        it 'not-equal' do
          expression.comparator = :!=
          expression.to_db.should == "attribute != 'value'"
        end

        it 'checks for inclusion' do
          expression.comparator = :in
          expression.value = [1, 2, 3]
          expression.to_db.should == "attribute IN (1,2,3)"
        end

        it 'checks for regexp matching' do
          expression.comparator = :=~
          expression.value = /value/
          expression.to_db.should == "attribute ~ 'value'"
        end
      end

      describe 'unions' do
        let(:lhs) { QueryExpression.new :first, :==, :one }
        let(:rhs) { QueryExpression.new :second, :==, :two }

        it 'converts | to an $or query' do
          (lhs | rhs).to_db.should == "(first = 'one' OR second = 'two')"
        end
      end

      describe 'intersections' do
        let(:lhs) { QueryExpression.new :first, :==, :one }
        let(:rhs) { QueryExpression.new :second, :==, :two }

        it 'converts & to an $and query' do
          (lhs & rhs).to_db.should == "(first = 'one' AND second = 'two')"
        end
      end
    end
  end
end
