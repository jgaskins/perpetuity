require 'perpetuity/validations/length'

module Perpetuity
  module Validations
    describe Length do
      let(:length) { Length.new :to_s, {}}

      describe 'minimum length' do
        before { length.at_least 4 }

        it 'invalidates' do
          length.pass?('abc').should be false
        end

        it 'validates' do
          length.pass?('abcd').should be true
        end
      end

      describe 'maximum length' do
        before { length.at_most 4 }

        it 'validates' do
          length.pass?('abcd').should be true
        end

        it 'invalidates' do
          length.pass?('abcde').should be false
        end
      end

      describe 'ranges' do
        before { length.between 4..5 }

        it 'invalidates values too short' do
          length.pass?('abc').should be false
        end

        it 'validates lengths at the low end' do
          length.pass?('abcd').should be true
        end

        it 'validates lengths at the high end' do
          length.pass?('abcde').should be true
        end

        it 'invalidates values too long' do
          length.pass?('abcdef').should be false
        end
      end
    end
  end
end
