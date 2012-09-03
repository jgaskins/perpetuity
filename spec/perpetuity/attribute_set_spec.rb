require 'perpetuity/attribute_set'

module Perpetuity
  describe AttributeSet do
    it 'contains attributes' do
      attribute = double('Attribute')
      subject << attribute

      subject.first.should eq attribute
    end

    it 'can access attributes by name' do
      user_attribute = double('Attribute', name: :user)
      subject << user_attribute

      subject[:user].should eq user_attribute
    end
  end
end
