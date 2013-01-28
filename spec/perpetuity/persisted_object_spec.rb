require 'perpetuity/persisted_object'

module Perpetuity
  describe PersistedObject do
    let(:object) { Object.new }

    before do
      object.instance_variable_set '@id', :fake_id
      object.extend PersistedObject
    end

    it 'gives an object an ID method' do
      object.id.should be == :fake_id
    end
  end
end
