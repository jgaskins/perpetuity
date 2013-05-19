require 'perpetuity/dereferencer'
require 'perpetuity/reference'

module Perpetuity
  describe Dereferencer do
    let(:registry) { double('Mapper Registry') }
    let(:mapper) { double('ObjectMapper') }
    let(:first) { double('Object', id: 1, class: Object) }
    let(:second) { double('Object', id: 2, class: Object) }
    let(:first_ref) { Reference.new(Object, 1) }
    let(:second_ref) { Reference.new(Object, 2) }
    let(:objects) { [first, second] }
    let(:derefer) { Dereferencer.new(registry) }

    context 'with one reference' do
      before do
        registry.should_receive(:[]).with(Object) { mapper }
        mapper.should_receive(:find).with(1) { first }
      end

      it 'loads objects based on the specified objects and attribute' do
        derefer.load first_ref
        derefer[first_ref].should == first
      end
    end

    context 'with no references' do
      it 'returns an empty array' do
        derefer.load(nil).should == []
      end
    end

    context 'with multiple references' do
      before do
        registry.should_receive(:[]).with(Object) { mapper }
        mapper.should_receive(:select) { objects }
      end

      it 'returns the array of dereferenced objects' do
        derefer.load([first_ref, second_ref]).should == objects
      end
    end
  end
end
