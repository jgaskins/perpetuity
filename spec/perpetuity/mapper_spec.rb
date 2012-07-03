$:.unshift('lib').uniq!
require 'perpetuity/mapper'
require 'test_classes'

module Perpetuity
  describe Mapper do
    it 'has correct attributes' do
      UserMapper.attributes.should eq [:name]
      ArticleMapper.attributes.should eq [:title, :body, :comments, :published_at, :views]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      EmptyMapper.attributes.should be_empty
    end

    it "knows which class it maps" do
      ArticleMapper.mapped_class.should eq Article
    end

    it 'gets the data from the first DB record and puts it into an object' do
      ArticleMapper.stub(data_source: double('data_source'))
      ArticleMapper.data_source.should_receive(:first).with(Article)
                               .and_return title: 'Moby Dick'
      ArticleMapper.first.title.should eq 'Moby Dick'
    end

    context 'with unserializable attributes' do
      let(:serialized_attrs) do
        [
          {
            type: :object,
            class: 'Comment',
            attributes: {
              body: 'Body',
            }
          }
        ]
      end

      it 'serializes attributes' do
        article = Article.new
        article.comments = [Comment.new]
        ArticleMapper.attributes_for(article)[:comments].should eq serialized_attrs
      end

      describe 'unserializes attributes' do
        let(:comments) { Mapper.unserialize(serialized_attrs)  }
        subject { comments.first }

        it { should be_a Comment }
        its(:body) { should eq 'Body' }
      end
    end

    it 'knows which mapper is needed for other classes' do
      Mapper.mapper_for(Article).should be ArticleMapper
    end

    describe 'instantiation' do
      let!(:article) { Article.new('My Title') }
      let!(:mapper) { ArticleMapper.new(article) }

      it 'can be instantiated' do
        mapper.object.title.should eq 'My Title'
      end

      it 'duplicates the object when instantiated' do
        article.title = 'My New Title'

        mapper.original_object.title.should eq 'My Title'
        mapper.object.title.should eq 'My New Title'
      end

      it 'knows what data has changed since last loaded' do
        article.title = 'My New Title'

        mapper.changed_attributes.should eq({ title: 'My New Title' })
      end
    end
  end
end
