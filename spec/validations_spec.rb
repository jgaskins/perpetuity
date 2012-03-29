require 'perpetuity/validations'

describe Perpetuity::ValidationSet do
  it 'contains validations' do
    subject.validations.should_not be_nil
  end

  it 'can add validations' do
    o = "Validation"
    subject << o

    subject.first.should == o
  end

  it 'validates an object' do
    o = "Validation"
    o.stub(pass?: true)
    subject << o

    subject.valid?("object").should be_true
  end

  it 'invalidates an object' do
    o = "Validation"
    o.stub(pass?: false)
    subject << o

    subject.valid?("object").should be_false
  end

  describe 'validation types' do
    let(:valid_object) { Object.new }

    it 'validates presence of an attribute' do
      valid_object.stub(email: 'me@example.com')
      subject.present :email

      subject.count.should == 1
      subject.valid?(valid_object).should be_true
    end

    it 'validates length of an attribute' do
      valid_object.stub(email: 'me@example.com')
      subject.length :email, at_most: 14
      subject.length :email, at_least: 14

      subject.count.should == 2
      subject.valid?(valid_object).should be_true
    end

    it 'invalidates when attribute is too short' do
      valid_object.stub(email: 'foo')
      subject.length :email, at_least: 4

      subject.count.should == 1
      subject.valid?(valid_object).should be_false
    end

    it 'invalidates when attribute is too long' do
      valid_object.stub(email: 'me@example.com')
      subject.length :email, at_most: 4

      subject.count.should == 1
      subject.valid?(valid_object).should be_false
    end
  end
end

describe Perpetuity::Validation do

end
