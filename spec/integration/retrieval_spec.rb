require 'spec_helper'
require 'support/test_classes'
require 'securerandom'

describe "retrieval" do
  let(:mapper) { Perpetuity[Article] }
  it "gets all the objects of a class" do
    expect { mapper.insert Article.new }.
      to change { mapper.all.to_a.count }.by 1
  end

  it "gets an item with a specific ID" do
    article = Article.new
    mapper.insert article
    retrieved = mapper.find(mapper.id_for article)

    mapper.id_for(retrieved).should be == mapper.id_for(article)
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
    mapper.all.limit(4).to_a.size.should eq 4
  end

  it 'counts result set' do
    title = "Foo #{Time.now.to_f}"
    mapper = Perpetuity[Article]
    5.times { mapper.insert Article.new(title) }
    mapper.count { |article| article.title == title }.should == 5
  end

  describe "Array-like syntax" do
    describe 'using comparison operators' do
      let(:draft) { Article.new 'Draft', 'draft content', nil, Time.now + 30 }
      let(:published) { Article.new 'Published', 'content', nil, Time.now - 30, 3 }

      let(:published_id) { mapper.id_for published }
      let(:draft_id) { mapper.id_for draft }

      before do
        mapper.insert draft
        mapper.insert published
      end

      it 'selects objects using equality' do
        selected = mapper.select { |article| article.title == 'Published' }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include published_id
        ids.should_not include draft_id
      end

      it 'selects objects using greater-than' do
        selected = mapper.select { |article| article.published_at < Time.now }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include published_id
        ids.should_not include draft_id
      end

      it 'selects objects using greater-than-or-equal' do
        selected = mapper.select { |article| article.views >= 3 }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include published_id
        ids.should_not include draft_id
      end

      it 'selects objects using less-than' do
        selected = mapper.select { |article| article.views < 3 }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include draft_id
        ids.should_not include published_id
      end

      it 'selects objects using less-than-or-equal' do
        selected = mapper.select { |article| article.views <= 0 }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include draft_id
        ids.should_not include published_id
      end

      it 'selects objects using inequality' do
        selected = mapper.select { |article| article.title != 'Draft' }
        ids = selected.map { |article| mapper.id_for article }
        ids.should_not include draft_id
        ids.should include published_id
      end

      it 'selects objects using regular expressions' do
        selected = mapper.select { |article| article.title =~ /Pub/ }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include published_id
        ids.should_not include draft_id
      end

      it 'selects objects using inclusion' do
        selected = mapper.select { |article| article.title.in %w( Published ) }
        ids = selected.map { |article| mapper.id_for article }
        ids.should include published_id
        ids.should_not include draft_id
      end
    end

    it 'selects objects that are truthy' do
      article_with_truthy_title = Article.new('I have a title')
      article_with_false_title = Article.new(false)
      article_with_nil_title = Article.new(nil)

      false_id  = mapper.insert article_with_false_title
      truthy_id = mapper.insert article_with_truthy_title
      nil_id    = mapper.insert article_with_nil_title

      selected = mapper.select { |article| article.title }
      ids = selected.map { |article| mapper.id_for(article) }

      ids.should     include truthy_id
      ids.should_not include false_id
      ids.should_not include nil_id
    end
  end

  describe 'counting results' do
    let(:title) { SecureRandom.hex }
    let(:articles) do
      2.times.map { Article.new(title) } + 2.times.map { Article.new }
    end

    before do
      articles.each { |article| mapper.insert article }
    end

    it 'counts the results' do
      query = mapper.select { |article| article.title == title }
      query.count.should == 2
    end

    it 'checks whether any results match' do
      mapper.any? { |article| article.title == title }.should be_truthy
      mapper.any? { |article| article.title == SecureRandom.hex }.should be_falsey
    end

    it 'checks whether all results match' do
      mapper.delete_all
      2.times { |i| mapper.insert Article.new(title, nil, nil, nil, i) }
      mapper.all? { |article| article.title == title }.should be_truthy
      mapper.all? { |article| article.views == 0 }.should be_falsey
    end

    it 'checks whether only one result matches' do
      unique_title = SecureRandom.hex
      mapper.insert Article.new(unique_title)
      mapper.one? { |article| article.title == unique_title }.should be_truthy
      mapper.one? { |article| article.title == title }.should be_falsey
      mapper.one? { |article| article.title == 'Title' }.should be_falsey
    end

    it 'checks whether no results match' do
      mapper.none? { |article| article.title == SecureRandom.hex }.should be_truthy
      mapper.none? { |article| article.title == title }.should be_falsey
    end
  end

  context 'with namespaced classes' do
    let(:article) { Article.new }
    let(:person) { CRM::Person.new }

    before { article.author = person }

    it 'gets a CRM::Person object back' do
      mapper.insert article
      retrieved_article = mapper.find(mapper.id_for article)
      mapper.load_association! retrieved_article, :author
      retrieved_article.author.should be_a CRM::Person
    end
  end

  it 'skips a specified number of objects' do
    title = SecureRandom.hex
    articles = 3.times.map { Article.new(title) }.sort_by { |article| mapper.id_for(article) }
    articles.each { |article| mapper.insert article }

    ret = mapper.select { |article| article.title == title }.drop(2).sort(:id).to_a
    ret.size.should eq 1
    ret.first.should == articles.last
  end

  describe 'selecting random objects' do
    it 'selects a random object' do
      mapper.delete_all
      articles = 3.times.map { Article.new(SecureRandom.hex) }
      articles.each { |article| mapper.insert article }

      articles.should include mapper.sample
    end
  end

  it 'does not unmarshal objects that were saved as strings' do
    fake_title = Marshal.dump(Object.new)
    id = mapper.insert Article.new(fake_title)

    retrieved = mapper.find(id)
    retrieved.title.should be_a String
    retrieved.title.should == fake_title
  end

  describe 'Enumerable methods within queries' do
    let(:article_with_comments) do
      Article.new(SecureRandom.hex, SecureRandom.hex).tap do |a|
        a.comments << Comment.new
      end
    end
    let(:article_without_comments) do
      Article.new(SecureRandom.hex, SecureRandom.hex)
    end
    let(:articles) { [ article_with_comments, article_without_comments ] }

    before { mapper.insert articles }

    it 'checks for the existence of attributes in an array' do
      results = mapper.select { |article| article.comments.any? }.to_a
      results.should include article_with_comments
      results.should_not include article_without_comments
    end

    it 'checks that an array has no elements' do
      results = mapper.select { |article| article.comments.none? }.to_a
      results.should include article_without_comments
      results.should_not include article_with_comments
    end
  end

  describe 'identity map' do
    let(:id) { mapper.insert Article.new }

    it 'returns the same object when requested with the same id' do
      mapper.find(id).should be mapper.find(id)
    end

    it 'returns the same object when requested with a block' do
      first = mapper.find { |article| article.id == id }
      second = mapper.find { |article| article.id == id }
      first.should be second
    end
  end
end
