require 'spec_helper'
require 'support/test_classes'

describe "retrieval" do
  it "gets all the objects of a class" do
    expect { Perpetuity[Article].insert Article.new }.
      to change { Perpetuity[Article].all.count }.by 1
  end

  it "has an ID when retrieved" do
    Perpetuity[Article].insert Article.new
    Perpetuity[Article].first.should respond_to :id
  end

  it "gets an item with a specific ID" do
    article = Article.new
    Perpetuity[Article].insert article
    retrieved = Perpetuity[Article].find(article.id)

    retrieved.id.should eq article.id
    retrieved.title.should eq article.title
    retrieved.body.should eq article.body
  end

  describe "Array-like syntax" do
    let(:draft) { Article.new 'Draft', 'draft content', nil, Time.now + 30 }
    let(:published) { Article.new 'Published', 'content', nil, Time.now - 30, 3 }
    before do
      Perpetuity[Article].insert draft
      Perpetuity[Article].insert published
    end

    it 'selects objects using equality' do
      selected = Perpetuity[Article].select { |article| article.title == 'Published' }
      selected.map(&:id).should include published.id
      selected.map(&:id).should_not include draft.id
    end

    it 'selects objects using greater-than' do
      selected = Perpetuity[Article].select { |article| article.published_at < Time.now }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end

    it 'selects objects using greater-than-or-equal' do
      selected = Perpetuity[Article].select { |article| article.views >= 3 }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end

    it 'selects objects using less-than' do
      selected = Perpetuity[Article].select { |article| article.views < 3 }
      ids = selected.map(&:id)
      ids.should include draft.id
      ids.should_not include published.id
    end

    it 'selects objects using less-than-or-equal' do
      selected = Perpetuity[Article].select { |article| article.views <= 0 }
      ids = selected.map(&:id)
      ids.should include draft.id
      ids.should_not include published.id
    end

    it 'selects objects using inequality' do
      selected = Perpetuity[Article].select { |article| article.title.not_equal? 'Draft' }
      ids = selected.map(&:id)
      ids.should_not include draft.id
      ids.should include published.id
    end

    it 'selects objects using regular expressions' do
      selected = Perpetuity[Article].select { |article| article.title =~ /Pub/ }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end

    it 'selects objects using inclusion' do
      selected = Perpetuity[Article].select { |article| article.title.in %w( Published ) }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end
  end
end
