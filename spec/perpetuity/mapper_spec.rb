require 'perpetuity/mapper'

module Perpetuity
  describe Mapper do
    let(:mapper) do
      Mapper.new
    end
    subject { mapper }

    it { should be_a Mapper }

    it 'has correct attributes' do
      Mapper.new { attribute :name, String }.attributes.should eq [:name]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      Mapper.new.attributes.should be_empty
    end

    it 'can have embedded attributes' do
      mapper_with_embedded_attrs = Mapper.new { attribute :comments, Array, embedded: true }
      mapper_with_embedded_attrs.attribute_set[:comments].should be_embedded
    end

    its(:mapped_class) { should eq Object }

    context 'with unserializable embedded attributes' do
      let(:unserializable_object) { 1.to_c }
      let(:serialized_attrs) do
        [ Marshal.dump(unserializable_object) ]
      end

      it 'serializes attributes' do
        object = Object.new
        object.stub(sub_objects: [unserializable_object])
        mapper.attribute :sub_objects, Array, embedded: true
        data_source = double(:data_source)
        mapper.stub(data_source: data_source)
        data_source.should_receive(:can_serialize?).with(unserializable_object).and_return false

        mapper.serialize(object)['sub_objects'].should eq serialized_attrs
      end
    end
  end
end
