require 'perpetuity/identity_map'

module Perpetuity
  describe IdentityMap do
    let(:id_map) { IdentityMap.new }

    context 'when the object exists in the IdentityMap' do
      let(:klass) do
        Class.new do
          attr_reader :id
          def initialize id
            @id = id
          end
        end
      end
      let(:object) { klass.new(1) }

      before do
        id_map << object
      end

      it 'returns the object with the given class and id' do
        retrieved = id_map[klass, 1]

        retrieved.id.should == 1
      end

      specify 'the object returned is the same object' do
        id_map[klass, 1].should be object
      end
    end

    context 'when the object does not exist in the IdentityMap' do
      it 'returns nil' do
        id_map[Object, 1].should be_nil
      end
    end
  end
end
