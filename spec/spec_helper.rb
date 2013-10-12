if ENV['PERPETUITY_ADAPTER'] == 'postgres'
  require 'perpetuity/postgres'
  Perpetuity.data_source :postgres, 'perpetuity_gem_test', user: ENV['USER'], password: nil
else
  require 'perpetuity/mongodb'
  Perpetuity.data_source :mongodb, 'perpetuity_gem_test'
end
