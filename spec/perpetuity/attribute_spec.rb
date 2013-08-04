require 'perpetuity/attribute'

module Perpetuity
  describe Attribute do
    let(:attribute) { Attribute.new :article, Object }
    subject { attribute }

    it 'has a name' do
      subject.name.should == :article
    end

    it 'has a type' do
      subject.type.should == Object
    end

    it 'can be embedded' do
      attribute = Attribute.new :article, Object, embedded: true
      attribute.should be_embedded
    end

    it 'can match a regex' do
      expect(attribute =~ /article/).to be_true
    end
  end
end
