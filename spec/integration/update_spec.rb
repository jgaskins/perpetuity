require 'spec_helper'
require 'support/test_classes'

describe 'updating' do
  let(:article) { Article.new }
  let(:mapper) { Perpetuity[Article] }
  let(:new_title) { 'I has a new title!' }

  before do
    mapper.insert article
  end

  it 'updates an object in the database' do
    mapper.update article, title: new_title
    mapper.find(article.id).title.should eq new_title
  end

  it 'updates the object in memory' do
    mapper.update article, title: new_title
    article.title.should eq new_title
  end

  it 'resaves the object in the database' do
    article.title = new_title
    mapper.save article
    mapper.find(article.id).title.should eq new_title
  end
end


