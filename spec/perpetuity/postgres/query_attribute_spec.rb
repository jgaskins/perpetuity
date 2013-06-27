require 'perpetuity/postgres/query_attribute'

module Perpetuity
  class Postgres
    describe QueryAttribute do
      let(:attribute) { QueryAttribute.new :attribute_name }
      subject { attribute }

      its(:name) { should == :attribute_name }

      it 'checks for equality' do
        (attribute == 1).should be_a QueryExpression
      end

      it 'checks for less than' do
        (attribute < 1).should be_a QueryExpression
      end

      it 'checks for <=' do
        (attribute <= 1).should be_a QueryExpression
      end

      it 'checks for greater than' do
        (attribute > 1).should be_a QueryExpression
      end

      it 'checks for >=' do
        (attribute >= 1).should be_a QueryExpression
      end

      it 'checks for inequality' do
        (attribute != 1).should be_a QueryExpression
      end

      it 'checks for regexp matches' do
        (attribute =~ /value/).should be_a QueryExpression
      end

      it 'checks for inclusion' do
        (attribute.in [1, 2, 3]).should be_a QueryExpression
      end
    end
  end
end
