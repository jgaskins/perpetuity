require 'perpetuity/config'
require 'perpetuity/postgres'

module Perpetuity
  describe Configuration do
    before(:all) { Perpetuity.register_standard_adapters }
    let(:config) { Configuration.new }

    it 'sets a data source' do
      config.data_source :postgres,
                         'perpetuity',
                         username: 'username',
                         password: 'password',
                         host: 'host',
                         port: 1337

      expect(config.data_source).to be_a Postgres
      expect(config.data_source.db).to eq 'perpetuity'
      expect(config.data_source.username).to eq 'username'
      expect(config.data_source.password).to eq 'password'
      expect(config.data_source.host).to eq 'host'
      expect(config.data_source.port).to eq 1337
    end

    it 'allows a URL as its data source' do
      db = "postgres://username:password@host:1337/database"
      data_source = config.data_source(db, pool_size: 20)
      expect(data_source).to be_a Postgres
      expect(data_source.username).to eq 'username'
      expect(data_source.password).to eq 'password'
      expect(data_source.host).to eq 'host'
      expect(data_source.port).to eq 1337
      expect(data_source.db).to eq 'database'
      expect(data_source.pool_size).to eq 20
    end

    it 'sets up a logger by default' do
      expect(config.logger).to be_a Logger
    end
  end
end
