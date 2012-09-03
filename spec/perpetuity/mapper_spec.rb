require 'perpetuity/mapper'
require 'test_classes'

module Perpetuity
  describe Mapper do
    let(:mapper) { Class.new(Mapper) }

    it 'has correct attributes' do
      mapper.attribute :name, String
      mapper.attributes.should eq [:name]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      mapper.attributes.should be_empty
    end

    it 'can have embedded attributes' do
      mapper.attribute :comments, Array, embedded: true
      mapper.attribute_set[:comments].should be_embedded
    end

    it "knows which class it maps" do
      ArticleMapper.mapped_class.should eq Article
    end

    context 'with unserializable attributes' do
      let(:serialized_attrs) do
        [ Marshal.dump(Comment.new) ]
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
  end
end
