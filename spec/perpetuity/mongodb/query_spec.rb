require 'perpetuity/mongodb/query'

module Perpetuity
  describe MongoDB::Query do
    let(:query) { MongoDB::Query }

    it 'generates Mongo equality expressions' do
      query.new{ |user| user.name == 'Jamie' }.to_db.should == {name: 'Jamie'}
    end

    it 'generates Mongo less-than expressions' do
      query.new{ |v| v.quantity < 10 }.to_db.should == {quantity: { '$lt' => 10}}
    end

    it 'generates Mongo less-than-or-equal expressions' do
      query.new{ |v| v.quantity <= 10 }.to_db.should == {quantity: { '$lte' => 10}}
    end

    it 'generates Mongo greater-than expressions' do
      query.new{ |v| v.quantity > 10 }.to_db.should == {quantity: { '$gt' => 10}}
    end

    it 'generates Mongo greater-than-or-equal expressions' do
      query.new{ |v| v.quantity >= 10 }.to_db.should == {quantity: { '$gte' => 10}}
    end

    it 'generates Mongo inequality expressions' do
      query.new{ |user| user.name.not_equal? 'Jamie' }.to_db.should == {
        name: {'$ne' => 'Jamie'}
      }
    end

    it 'generates Mongo regexp expressions' do
      query.new{ |user| user.name =~ /Jamie/ }.to_db.should == {name: /Jamie/}
    end
  end
end
