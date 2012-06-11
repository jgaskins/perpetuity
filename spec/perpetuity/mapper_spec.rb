$:.unshift('lib').uniq!
require 'perpetuity/mapper'
require 'test_classes'

module Perpetuity
  describe Mapper do
    it 'has correct attributes' do
      UserMapper.attributes.should == [:name]
      ArticleMapper.attributes.should == [:title, :body]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      EmptyMapper.attributes.should be_empty
    end

    it "knows which class it maps" do
      ArticleMapper.mapped_class.should == Article
    end

    it 'gets the data from the first DB record and puts it into an object' do
      ArticleMapper.stub(data_source: double('data_source'))
      ArticleMapper.data_source.should_receive(:first).with(Article)
                               .and_return title: 'Moby Dick'
      ArticleMapper.first.title.should == 'Moby Dick'
    end

    describe 'instantiation' do
      let!(:article) { Article.new(title = 'My Title') }
      let!(:mapper) { ArticleMapper.new(article) }

      it 'can be instantiated' do
        mapper.object.title.should == 'My Title'
      end

      it 'duplicates the object when instantiated' do
        article.title = 'My New Title'

        mapper.original_object.title.should == 'My Title'
        mapper.object.title.should == 'My New Title'
      end

      it 'knows what data has changed since last loaded' do
        article.title = 'My New Title'

        mapper.changed_attributes.should == { title: 'My New Title' }
      end
    end
  end
end
