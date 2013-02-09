require 'perpetuity'

Perpetuity.configure do
  data_source Perpetuity::MongoDB.new db: 'perpetuity_gem_test'
end

