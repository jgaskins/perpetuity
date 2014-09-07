require 'perpetuity/attribute'

module Perpetuity
  describe Attribute do
    let(:attribute) { Attribute.new :article, Object, default: 1 }
    subject { attribute }

    it 'has a name' do
      expect(subject.name).to be == :article
    end

    it 'has a type' do
      expect(subject.type).to be == Object
    end

    it 'can get extra options' do
      expect(attribute.options).to be == { default: 1 }
      expect(attribute.options(:default)).to be == 1
    end

    it 'can be embedded' do
      attribute = Attribute.new :article, Object, embedded: true
      expect(attribute).to be_embedded
    end

    it 'can match a regex' do
      expect(attribute =~ /article/).to be_truthy
    end

    it 'uses its name when converted to a string' do
      expect(attribute.to_s).to be == 'article'
    end
  end
end
