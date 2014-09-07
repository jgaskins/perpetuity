require 'perpetuity/dereferencer'
require 'perpetuity/reference'

module Perpetuity
  describe Dereferencer do
    let(:mapper) { double('ObjectMapper') }
    let(:first) { double('Object', class: Object) }
    let(:second) { double('Object', class: Object) }
    let(:first_ref) { Reference.new(Object, 1) }
    let(:second_ref) { Reference.new(Object, 2) }
    let(:objects) { [first, second] }
    let(:registry) { { Object => mapper } }
    let(:derefer) { Dereferencer.new(registry) }

    context 'with one reference' do
      it 'loads objects based on the specified objects and attribute' do
        first.instance_variable_set :@id, 1
        expect(mapper).to receive(:find).with(1) { first }
        id_map = IdentityMap.new
        allow(derefer).to receive(:map) { id_map }
        allow(registry).to receive(:mapper_for)
                       .with(Object, identity_map: id_map)
                       .and_return mapper

        derefer.load first_ref
        id = derefer[first_ref].instance_variable_get(:@id)
        expect(id).to be == 1
      end
    end

    context 'with no references' do
      it 'returns an empty array' do
        expect(derefer.load(nil)).to be == []
      end
    end

    context 'with multiple references' do
      it 'returns the array of dereferenced objects' do
        expect(mapper).to receive(:find).with([1, 2]) { objects }
        expect(derefer.load([first_ref, second_ref])).to be == objects
      end
    end
  end
end
