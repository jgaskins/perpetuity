$:.unshift('lib').uniq!
require 'perpetuity/mongodb/query_attribute'

module Perpetuity
  describe MongoDB::QueryAttribute do
    let(:attribute) { MongoDB::QueryAttribute.new :attribute_name }
    subject { attribute }

    its(:name) { should == :attribute_name }

    it 'checks for equality' do
      (attribute == 1).should be_a MongoDB::QueryExpression
    end

    it 'checks for less than' do
      (attribute < 1).should be_a MongoDB::QueryExpression
    end

    it 'checks for <=' do
      (attribute <= 1).should be_a MongoDB::QueryExpression
    end

    it 'checks for greater than' do
      (attribute > 1).should be_a MongoDB::QueryExpression
    end

    it 'checks for >=' do
      (attribute >= 1).should be_a MongoDB::QueryExpression
    end

    it 'checks for inequality' do
      attribute.not_equal?(1).should be_a MongoDB::QueryExpression
    end

    it 'checks for regexp matches' do
      (attribute =~ /value/).should be_a MongoDB::QueryExpression
    end

    it 'checks for inclusion' do
      (attribute.in [1, 2, 3]).should be_a MongoDB::QueryExpression
    end
  end
end
