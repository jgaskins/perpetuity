require 'perpetuity'
require 'test_classes'

describe Perpetuity::AttributeSet do
  it 'contains attributes' do
    subject << Perpetuity::Attribute.new(:article, Article)
    subject.first.name.should == :article
    subject.first.type.should == Article
  end

  it 'can access attributes by name' do
    subject << Perpetuity::Attribute.new(:article, Article)
    subject << Perpetuity::Attribute.new(:user, User)

    subject[:user].type.should == User
  end
end
