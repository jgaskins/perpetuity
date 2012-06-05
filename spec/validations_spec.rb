require 'perpetuity/validations'

module Perpetuity
  describe ValidationSet do
    let(:validation_set) { ValidationSet.new }
    it 'is empty when created' do
      validation_set.should be_empty
    end

    it 'can add validations' do
      v = double('validation')
      validation_set << v

      validation_set.first.should == v
    end

    it 'validates an object' do
      v = double('validation')
      v.stub(pass?: true)
      validation_set << v

      validation_set.should be_valid(double('object'))
    end

    it 'invalidates an object' do
      v = double('validation')
      v.stub(pass?: false)
      validation_set << v

      validation_set.should_not be_valid(double('object'))
    end

    describe 'validation types' do
      let(:valid_object) { double('valid object') }
      let(:invalid_object) { double('invalid object') }

      it 'validates presence of an attribute' do
        valid_object.stub(email: 'me@example.com')
        validation_set.present :email

        validation_set.count.should == 1
        validation_set.should be_valid(valid_object)
      end

      it 'validates length of an attribute' do
        valid_object.stub(email: 'me@example.com')
        validation_set.length :email, at_most: 14
        validation_set.length :email, at_least: 14

        validation_set.count.should == 2
        validation_set.should be_valid(valid_object)
      end

      it 'invalidates when attribute is too short' do
        invalid_object.stub(email: 'foo')
        validation_set.length :email, at_least: 4

        validation_set.count.should == 1
        validation_set.should be_invalid(invalid_object)
      end

      it 'invalidates when attribute is too long' do
        invalid_object.stub(email: 'me@example.com')
        subject.length :email, at_most: 4

        subject.count.should == 1
        subject.should be_invalid(invalid_object)
      end
    end
  end
end
