require 'perpetuity/attribute'

describe Perpetuity::Attribute do
  subject { Perpetuity::Attribute.new :article, Object }
  it 'has a name' do
    subject.name.should == :article
  end

  it 'has a type' do
    subject.type.should == Object
  end
end
