require 'perpetuity'
require 'test_classes'

describe Perpetuity::Attribute do
  subject { Perpetuity::Attribute.new :article, Article }
  it 'has a name' do
    subject.name.should == :article
  end

  it 'has a type' do
    subject.type.should == Article
  end
end
