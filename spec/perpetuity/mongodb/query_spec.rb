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

    describe 'negated queries' do
      it 'negates an equality query' do
        q = query.new { |user| user.name == 'Jamie' }
        q.negate.to_db.should == { name: { '$ne' => 'Jamie' } }
      end

      it 'negates a not-equal query' do
        q = query.new { |account| account.balance != 10 }
        q.negate.to_db.should == { balance: { '$not' => { '$ne' => 10 } } }
      end

      it 'negates a less-than query' do
        q = query.new { |account| account.balance < 10 }
        q.negate.to_db.should == { balance: { '$not' => { '$lt' => 10 } } }
      end

      it 'negates a less-than-or-equal query' do
        q = query.new { |account| account.balance <= 10 }
        q.negate.to_db.should == { balance: { '$not' => { '$lte' => 10 } } }
      end

      it 'negates a greater-than query' do
        q = query.new { |account| account.balance > 10 }
        q.negate.to_db.should == { balance: { '$not' => { '$gt' => 10 } } }
      end

      it 'negates a greater-than-or-equal query' do
        q = query.new { |account| account.balance >= 10 }
        q.negate.to_db.should == { balance: { '$not' => { '$gte' => 10 } } }
      end

      it 'negates a regex query' do
        q = query.new { |account| account.name =~ /Jamie/ }
        q.negate.to_db.should == { name: { '$not' => /Jamie/ } }
      end

      it 'negates a inclusion query' do
        q = query.new { |article| article.tags.in ['tag1', 'tag2'] }
        q.negate.to_db.should == { tags: { '$not' => { '$in' => ['tag1', 'tag2'] } } }
      end
    end
  end
end
