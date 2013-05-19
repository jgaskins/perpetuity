require 'perpetuity/dereferencer'
require 'perpetuity/reference'

module Perpetuity
  describe Dereferencer do
    let(:registry) { double('Mapper Registry') }
    let(:mapper) { double('ObjectMapper') }
    let(:object) { double('Object', id: 1, class: Object) }
    let(:reference) { Reference.new(Object, 1) }
    let(:objects) { [object] }
    let(:derefer) { Dereferencer.new(registry) }

    context 'with one reference' do
      before do
        registry.should_receive(:[]).with(Object) { mapper }
        mapper.should_receive(:find).with(1) { object }
      end

      it 'loads objects based on the specified objects and attribute' do
        derefer.load reference
        derefer[reference].should == object
      end
    end

    context 'with no references' do
      it 'returns an empty array' do
        derefer.load(nil).should == []
      end
    end

    context 'with multiple references' do
      let(:returned_array) { [object, object] }

      before do
        registry.should_receive(:[]).with(Object) { mapper }
        mapper.should_receive(:select) { returned_array }
      end

      it 'returns the array of dereferenced objects' do
        derefer.load([reference, reference]).should == returned_array
      end
    end
  end
end
