require 'spec_helper'
require 'support/test_classes'

describe 'enumerable syntax' do
  let(:mapper) { Perpetuity[Article] }

  let(:current_time) { Time.now }
  let(:foo) { Article.new("Foo #{Time.now.to_f}", '', nil, current_time - 60) }
  let(:bar) { Article.new("Bar #{Time.now.to_f}", '', nil, current_time + 60) }

  before do
    mapper.insert foo
  end

  it 'finds a single object based on criteria' do
    expect(mapper.find { |a| a.title == foo.title }).to be == foo
  end

  context 'excludes objects based on criteria' do
    before do
      mapper.insert bar
    end

    it 'excludes on equality' do
      articles = mapper.reject { |a| a.title == bar.title }.to_a
      expect(articles).to include foo
      expect(articles).not_to include bar
    end

    it 'excludes on inequality' do
      articles = mapper.reject { |a| a.published_at <= current_time }.to_a
      expect(articles).to include bar
      expect(articles).not_to include foo
    end

    it 'excludes on not-equal' do
      articles = mapper.reject { |a| a.title != foo.title }.to_a
      expect(articles).to include foo
      expect(articles).not_to include bar
    end

    it 'excludes on regex match' do
      articles = mapper.reject { |a| a.title =~ /Foo/ }.to_a
      expect(articles).to include bar
      expect(articles).not_to include foo
    end
  end
end
