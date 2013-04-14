require 'spec_helper'
require 'support/test_classes'

describe 'enumerable syntax' do
  let(:mapper) { Perpetuity[Article] }

  it 'finds a single object based on criteria' do
    article = Article.new('foo')
    mapper.insert article
    mapper.find { |a| a.title == 'foo' }.should be == article
  end
end
