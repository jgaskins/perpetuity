require 'perpetuity/rails/mapper_reloader'
require 'perpetuity/rails_model'

module Perpetuity
  def self.insert_mapper_reloader_middleware
    ::Rails.application.config.middleware.use Rails::MapperReloader
  end
end

Perpetuity.insert_mapper_reloader_middleware
