require 'perpetuity/mongodb/index'

module Perpetuity
  class MongoDB
    describe Index do
      let(:attribute) { double(name: 'name') }
      let(:index) { Index.new(Object, attribute) }

      it 'is not active by default' do
        index.should_not be_active
      end

      it 'can be activated' do
        index.activate!
        index.should be_active
      end

      it 'can be unique' do
        index = Index.new(Object, attribute, unique: true)
        index.should be_unique
      end

      it 'is not unique by default' do
        index.should_not be_unique
      end

      describe 'index ordering' do
        it 'can be ordered in ascending order' do
          index = Index.new(Object, attribute, order: :ascending)
          index.order.should be :ascending
        end

        it 'is ordered ascending by default' do
          index.order.should be :ascending
        end

        it 'can be ordered in descending order' do
          index = Index.new(Object, attribute, order: :descending)
          index.order.should be :descending
        end
      end
    end
  end
end
