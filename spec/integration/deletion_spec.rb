require 'spec_helper'
require 'support/test_classes'

describe "deletion" do
  it 'deletes an object' do
    2.times { Perpetuity[Article].insert Article.new }
    expect { Perpetuity[Article].delete Perpetuity[Article].first }.to change { Perpetuity[Article].count }.by(-1)
  end

  it 'deletes an object with a given id' do
    article_id = Perpetuity[Article].insert Article.new
    expect {
      Perpetuity[Article].delete article_id
    }.to change { Perpetuity[Article].count }.by(-1)
  end

  it 'deletes an array of objects' do
    mapper = Perpetuity[Article]
    articles = Array.new(2) { Article.new }
    mapper.insert articles
    expect { mapper.delete articles }.to change { mapper.count }.by -2
  end

  describe "#delete_all" do
    it "should delete all objects of a certain class" do
      Perpetuity[Article].insert Article.new
      Perpetuity[Article].delete_all
      expect(Perpetuity[Article].count).to eq 0
    end
  end
end
