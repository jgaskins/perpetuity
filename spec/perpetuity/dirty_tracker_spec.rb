require 'perpetuity/dirty_tracker'

module Perpetuity
  describe DirtyTracker do
    let(:mapper) { double('ObjectMapper') }
    let(:tracker) { DirtyTracker.new }

    context 'when the object exists in the IdentityMap' do
      let(:klass) do
        Class.new do
          attr_accessor :id, :name
          def initialize id, name
            @id = id
            @name = name
          end
        end
      end
      let(:object) { klass.new(1, 'foo') }

      before do
        mapper.stub(:id_for).with(object) { object.id }
        tracker << object
      end

      it 'returns the object with the given class and id' do
        object.name = 'bar'
        retrieved = tracker[klass, 1]

        retrieved.id.should == 1
        retrieved.name.should == 'foo'
      end

      specify 'the object returned is a duplicate' do
        tracker[klass, 1].should_not be object
      end

      it 'stringifies keys when checking' do
        retrieved = tracker[klass, '1']
        retrieved.id.should == 1
      end
    end

    context 'when the object does not exist in the IdentityMap' do
      it 'returns nil' do
        tracker[Object, 1].should be_nil
      end
    end
  end
end
