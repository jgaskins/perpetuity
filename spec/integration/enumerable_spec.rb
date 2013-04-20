require 'spec_helper'
require 'support/test_classes'

describe 'enumerable syntax' do
  let(:mapper) { Perpetuity[Article] }

  it 'finds a single object based on criteria' do
    article = Article.new('foo')
    mapper.insert article
    mapper.find { |a| a.title == 'foo' }.should be == article
  end

  it 'excludes objects based on criteria' do
    foo = Article.new('foo')
    bar = Article.new('bar')
    mapper.insert foo
    mapper.insert bar

    articles = mapper.reject { |a| a.title == 'bar' }.to_a
    articles.should include foo
    articles.should_not include bar
  end
end
