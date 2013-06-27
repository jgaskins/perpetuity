require 'perpetuity/mongodb/query_attribute'

module Perpetuity
  describe MongoDB::QueryAttribute do
    let(:attribute) { MongoDB::QueryAttribute.new :attribute_name }
    subject { attribute }

    its(:name) { should == :attribute_name }

    it 'allows checking subattributes' do
      attribute.title.name.should == :'attribute_name.title'
    end

    it 'wraps .id subattribute in metadata' do
      attribute.id.name.should == :'attribute_name.__metadata__.id'
    end

    it 'wraps .klass subattribute in metadata' do
      attribute.klass.name.should == :'attribute_name.__metadata__.class'
    end

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
      (attribute != 1).should be_a MongoDB::QueryExpression
    end

    it 'checks for regexp matches' do
      (attribute =~ /value/).should be_a MongoDB::QueryExpression
    end

    it 'checks for inclusion' do
      (attribute.in [1, 2, 3]).should be_a MongoDB::QueryExpression
    end

    it 'checks for its own truthiness' do
      attribute.to_db.should == ((attribute != false) & (attribute != nil)).to_db
    end
  end
end
