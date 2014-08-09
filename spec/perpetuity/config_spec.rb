require 'perpetuity/config'
require 'perpetuity/postgres'

module Perpetuity
  describe Configuration do
    let(:config) { Configuration.new }

    it 'sets a data source' do
      config.data_source :postgres,
                         'perpetuity',
                         username: 'username',
                         password: 'password',
                         host: 'host',
                         port: 1337

      config.data_source.should be_a Postgres
      config.data_source.db.should == 'perpetuity'
      config.data_source.username.should == 'username'
      config.data_source.password.should == 'password'
      config.data_source.host.should == 'host'
      config.data_source.port.should == 1337
    end

    it 'allows a URL as its data source' do
      db = "postgres://username:password@host:1337/database"
      data_source = config.data_source(db, pool_size: 20)
      data_source.should be_a Postgres
      data_source.username.should == 'username'
      data_source.password.should == 'password'
      data_source.host.should == 'host'
      data_source.port.should == 1337
      data_source.db.should == 'database'
      data_source.pool_size.should == 20
    end

    it 'sets up a logger by default' do
      config.logger.should be_a Logger
    end
  end
end
