require 'spec_helper'
require 'support/test_classes'

describe Perpetuity do
  describe 'mapper generation' do
    it 'generates mappers' do
      Perpetuity.generate_mapper_for Object
      Perpetuity[Object].should be_a Perpetuity::Mapper
    end

    it 'provides a DSL within the generated mapper' do
      Perpetuity.generate_mapper_for Object do
        id { object_id + 1 }
        attribute :object_id
      end

      mapper = Perpetuity[Object]
      object = Object.new
      mapper.insert object
      object.id.should eq object.object_id + 1
      mapper.attributes.should eq [:object_id]
    end
  end

  describe 'methods on mappers' do
    it 'allows methods to act as scopes' do
      published = Article.new('Published', 'I love cats', nil, Time.now - 30)
      draft = Article.new('Draft', 'I do not like moose', nil, nil)
      not_yet_published = Article.new('Tomorrow', 'Dogs', nil, Time.now + 30)

      mapper = Perpetuity[Article]
      mapper.insert published
      mapper.insert draft
      mapper.insert not_yet_published

      published_ids = mapper.published.to_a.map(&:id)
      published_ids.should include published.id
      published_ids.should_not include draft.id, not_yet_published.id

      unpublished_ids = mapper.unpublished.to_a.map(&:id)
      unpublished_ids.should_not include published.id
      unpublished_ids.should include draft.id, not_yet_published.id
    end
  end
end
