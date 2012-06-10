$:.unshift('lib').uniq!
require 'perpetuity/config'

module Perpetuity
  describe Configuration do
    let(:config) { Configuration.new }

    it 'sets a data source' do
      db = double('db')
      config.data_source db
      config.data_source.should == db
    end
  end
end
