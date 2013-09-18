require 'perpetuity'

if ENV['PERPETUITY_ADAPTER'] == 'postgres'
  Perpetuity.data_source :postgres, 'perpetuity_gem_test', user: ENV['USER'], password: nil
else
  Perpetuity.data_source :mongodb, 'perpetuity_gem_test'
end
