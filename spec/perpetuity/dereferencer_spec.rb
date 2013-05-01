require 'perpetuity/dereferencer'
require 'perpetuity/reference'

module Perpetuity
  describe Dereferencer do
    let(:registry) { double('Mapper Registry') }
    let(:mapper) { double('ObjectMapper') }
    let(:object) { double('Object', id: 1, class: Object) }
    let(:reference) { Reference.new(Object, 1) }
    let(:objects) { [object] }

    before do
      registry.should_receive(:[]).with(Object) { mapper }
      mapper.should_receive(:select) { objects }
    end

    it 'loads objects based on the specified objects and attribute' do
      derefer = Dereferencer.new(registry)
      derefer.load reference
      derefer[reference].should == object
    end
  end
end
