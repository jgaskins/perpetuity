require 'perpetuity/rails'
require 'support/stubbed_rails'

module Perpetuity
  describe 'rails support' do
    before do
      stub_const '::Rails', StubbedRails
      Perpetuity.add_rails_support!
    end

    it 'inserts MapperReloader into the middleware' do
      ::Rails.application.config.middleware.should include Rails::MapperReloader
    end
  end
end
