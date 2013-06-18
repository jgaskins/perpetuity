require 'support/stubbed_rails'
require 'perpetuity/rails'

module Perpetuity
  describe 'rails support' do
    before do
      Perpetuity.insert_mapper_reloader_middleware
    end

    it 'inserts MapperReloader into the middleware' do
      ::Rails.application.config.middleware.should include Rails::MapperReloader
    end
  end
end
