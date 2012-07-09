require 'perpetuity/attribute'

describe Perpetuity::Attribute do
  subject { Perpetuity::Attribute.new :article, Object }
  it 'has a name' do
    subject.name.should == :article
  end

  it 'has a type' do
    subject.type.should == Object
  end

  it 'can be embedded' do
    attribute = Perpetuity::Attribute.new :article, Object, embedded: true
    attribute.should be_embedded
  end
end
