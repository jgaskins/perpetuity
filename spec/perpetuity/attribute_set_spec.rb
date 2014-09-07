require 'perpetuity/attribute_set'

module Perpetuity
  describe AttributeSet do
    it 'contains attributes' do
      attribute = double('Attribute', name: :foo)
      subject << attribute

      expect(subject.first).to eq attribute
    end

    it 'can access attributes by name' do
      user_attribute = double('Attribute', name: :user)
      subject << user_attribute

      expect(subject[:user]).to eq user_attribute
    end
  end
end
