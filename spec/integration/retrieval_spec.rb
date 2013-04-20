require 'spec_helper'
require 'support/test_classes'
require 'securerandom'

describe "retrieval" do
  let(:mapper) { Perpetuity[Article] }

  it "gets all the objects of a class" do
    expect { mapper.insert Article.new }.
      to change { mapper.all.count }.by 1
  end

  it "has an ID when retrieved" do
    mapper.insert Article.new
    mapper.first.should respond_to :id
  end

  it "gets an item with a specific ID" do
    article = Article.new
    mapper.insert article
    retrieved = mapper.find(article.id)

    retrieved.id.should eq article.id
    retrieved.title.should eq article.title
    retrieved.body.should eq article.body
  end

  describe 'sorting' do
    let(:first) { Article.new('First', '', nil, Time.now - 20) }
    let(:second) { Article.new('Second', '', nil, Time.now - 10) }
    let(:third) { Article.new('Third', '', nil, Time.now) }

    before do
      mapper.delete_all
      [second, third, first].each { |article| mapper.insert article }
    end

    it 'sorts results' do
      titles = mapper.all.sort(:published_at).map(&:title)
      titles.should be == %w(First Second Third)
    end

    it 'reverse-sorts results' do
      titles = mapper.all.sort(:published_at).reverse.map(&:title)
      titles.should be == %w(Third Second First)
    end
  end

  it 'limits result set' do
    5.times { mapper.insert Article.new }
    mapper.all.limit(4).to_a.should have(4).items
  end

  it 'counts result set' do
    title = "Foo #{Time.now.to_f}"
    mapper = Perpetuity[Article]
    5.times { mapper.insert Article.new(title) }
    mapper.count { |article| article.title == title }.should == 5
  end

  describe "Array-like syntax" do
    let(:draft) { Article.new 'Draft', 'draft content', nil, Time.now + 30 }
    let(:published) { Article.new 'Published', 'content', nil, Time.now - 30, 3 }
    before do
      mapper.insert draft
      mapper.insert published
    end

    it 'selects objects using equality' do
      selected = mapper.select { |article| article.title == 'Published' }
      selected.map(&:id).should include published.id
      selected.map(&:id).should_not include draft.id
    end

    it 'selects objects using greater-than' do
      selected = mapper.select { |article| article.published_at < Time.now }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end

    it 'selects objects using greater-than-or-equal' do
      selected = mapper.select { |article| article.views >= 3 }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end

    it 'selects objects using less-than' do
      selected = mapper.select { |article| article.views < 3 }
      ids = selected.map(&:id)
      ids.should include draft.id
      ids.should_not include published.id
    end

    it 'selects objects using less-than-or-equal' do
      selected = mapper.select { |article| article.views <= 0 }
      ids = selected.map(&:id)
      ids.should include draft.id
      ids.should_not include published.id
    end

    it 'selects objects using inequality' do
      selected = mapper.select { |article| article.title != 'Draft' }
      ids = selected.map(&:id)
      ids.should_not include draft.id
      ids.should include published.id
    end

    it 'selects objects using regular expressions' do
      selected = mapper.select { |article| article.title =~ /Pub/ }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end

    it 'selects objects using inclusion' do
      selected = mapper.select { |article| article.title.in %w( Published ) }
      ids = selected.map(&:id)
      ids.should include published.id
      ids.should_not include draft.id
    end
  end

  describe 'counting results' do
    let(:title) { SecureRandom.hex }
    let(:articles) do
      5.times.map { Article.new(title) } + 5.times.map { Article.new }
    end

    before do
      articles.each { |article| mapper.insert article }
    end

    it 'counts the results' do
      query = mapper.select { |article| article.title == title }
      query.count.should == 5
    end
  end

  context 'with namespaced classes' do
    let(:article) { Article.new }
    let(:person) { CRM::Person.new }

    before { article.author = person }

    it 'gets a CRM::Person object back' do
      mapper.insert article
      retrieved_article = mapper.find(article.id)
      mapper.load_association! retrieved_article, :author
      retrieved_article.author.should be_a CRM::Person
    end
  end
end
