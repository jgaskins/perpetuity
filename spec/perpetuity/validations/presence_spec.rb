$:.unshift('lib').uniq!
require 'perpetuity/validations/presence'

module Perpetuity
  module Validations
    describe Presence do
      let(:presence) { Presence.new :to_s }
      let(:valid) { double('valid object') }
      let(:invalid) { double('invalid object') }

      it 'validates values that are present' do
        presence.pass?(valid).should be_true
      end

      it 'invalidates nil values' do
        invalid.stub(to_s: nil)
        presence.pass?(invalid).should be_false
      end

      it 'invalidates empty strings' do
        invalid.stub(to_s: '')
        presence.pass?(invalid).should be_false
      end

      it 'invalidates strings with only whitespace' do
        invalid.stub(to_s: ' ')
        presence.pass?(invalid).should be_false
      end
    end
  end
end
