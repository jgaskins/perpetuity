require 'perpetuity/mapper'
require 'test_classes'

module Perpetuity
  describe Mapper do
    let(:mapper) { Mapper[Article] }
    subject { mapper }

    it { should be_a Mapper }

    it 'has correct attributes' do
      Mapper.new { attribute :name, String }.attributes.should eq [:name]
    end

    it 'returns an empty attribute list when no attributes have been assigned' do
      Mapper.new.attributes.should be_empty
    end

    it 'can have embedded attributes' do
      mapper_with_embedded_attrs = Mapper.new { attribute :comments, Array, embedded: true }
      mapper_with_embedded_attrs.attribute_set[:comments].should be_embedded
    end

    its(:mapped_class) { should eq Article }

    context 'with unserializable attributes' do
      let(:serialized_attrs) do
        [ Marshal.dump(Comment.new) ]
      end

      it 'serializes attributes' do
        article = Article.new
        article.comments = [Comment.new]
        mapper.attributes_for(article)[:comments].should eq serialized_attrs
      end

      describe 'unserializes attributes' do
        let(:comments) { mapper.unserialize(serialized_attrs)  }
        subject { comments.first }

        it { should be_a Comment }
        its(:body) { should eq 'Body' }
      end
    end
  end
end
