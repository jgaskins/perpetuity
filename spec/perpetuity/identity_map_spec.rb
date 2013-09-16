require 'perpetuity/identity_map'

module Perpetuity
  describe IdentityMap do
    let(:id_map) { IdentityMap.new }

    context 'when the object exists in the IdentityMap' do
      let(:object) { Object.new }

      before do
        object.instance_variable_set :@id, 1
        id_map << object
      end

      it 'returns the object with the given class and id' do
        retrieved = id_map[Object, 1]

        retrieved.instance_variable_get(:@id).should == 1
      end

      specify 'the object returned is a duplicate, not the same object' do
        id_map[Object, 1].should_not be object
      end

      it 'stringifies keys when checking' do
        retrieved = id_map[Object, '1']
        retrieved.instance_variable_get(:@id).should == 1
      end
    end

    context 'when the object does not exist in the IdentityMap' do
      it 'returns nil' do
        id_map[Object, 1].should be_nil
      end
    end
  end
end
