require 'perpetuity/attribute'

module Perpetuity
  describe Attribute do
    let(:attribute) { Attribute.new :article, Object, default: 1 }
    subject { attribute }

    it 'has a name' do
      subject.name.should == :article
    end

    it 'has a type' do
      subject.type.should == Object
    end

    it 'can get extra options' do
      attribute.options.should == { default: 1 }
      attribute.options(:default).should == 1
    end

    it 'can be embedded' do
      attribute = Attribute.new :article, Object, embedded: true
      attribute.should be_embedded
    end

    it 'can match a regex' do
      expect(attribute =~ /article/).to be_truthy
    end

    it 'uses its name when converted to a string' do
      attribute.to_s.should == 'article'
    end
  end
end
