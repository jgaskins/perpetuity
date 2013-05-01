require 'perpetuity/identity_map'

module Perpetuity
  describe IdentityMap do
    context 'when the object exists in the IdentityMap' do
      let(:object) { double('Object', id: 1, class: Object) }

      it 'returns the object with the given class and id' do
        id_map = IdentityMap.new
        id_map << object
        id_map[Object, 1].should == object
      end
    end

    context 'when the object does not exist in the IdentityMap' do
      it 'returns nil' do
        id_map = IdentityMap.new
        id_map[Object, 1].should be_nil
      end
    end
  end
end
