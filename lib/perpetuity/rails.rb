require 'perpetuity/rails/mapper_reloader'

module Perpetuity
  def self.add_rails_support!
    ::Rails.application.config.middleware.use Rails::MapperReloader
  end

  add_rails_support! if defined? ::Rails
end
