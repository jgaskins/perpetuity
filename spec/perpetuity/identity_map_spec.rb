require 'perpetuity/identity_map'

module Perpetuity
  describe IdentityMap do
    let(:object_mapper) { double('Mapper', id_for: 1) }
    let(:object) { double('Object', class: Object) }
    let(:id_map) { IdentityMap.new }

    context 'when the object exists in the IdentityMap' do
      let(:object) { double('Object', class: Object) }

      before { object.instance_variable_set :@id, 1 }

      it 'returns the object with the given class and id' do
        id_map << object
        id_map[Object, 1].should == object
      end

      it 'stringifies keys when checking' do
        id_map << object
        id_map[Object, '1'].should == object
      end
    end

    context 'when the object does not exist in the IdentityMap' do
      it 'returns nil' do
        id_map[Object, 1].should be_nil
      end
    end
  end
end
