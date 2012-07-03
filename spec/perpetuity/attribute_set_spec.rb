require 'perpetuity/attribute_set'
require 'perpetuity/attribute'

module Perpetuity
  describe AttributeSet do
    it 'contains attributes' do
      subject << Attribute.new(:article, Object)
      subject.first.name.should eq :article
      subject.first.type.should eq Object
    end

    it 'can access attributes by name' do
      subject << Attribute.new(:article, Object)
      subject << Attribute.new(:user, Object)

      subject[:user].type.should eq Object
    end
  end
end
