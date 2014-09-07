require 'perpetuity/rails_model'

module Perpetuity
  describe RailsModel do
    let(:klass) do
      Class.new do
        include Perpetuity::RailsModel
        attr_accessor :id
      end
    end
    let(:object) { klass.new }
    let(:wrapper) { object.to_model }

    it 'determines whether it is persisted based on @id ivar' do
      expect(object).not_to be_persisted
      object.id = 'lol'
      expect(object).to be_persisted
    end

    it 'returns the id as to_param' do
      expect(object.to_param).to be == nil
      object.id = 'foo'
      expect(object.to_param).to be == 'foo'
    end

    it 'returns the keys on the object' do
      expect(object.to_key).to be == nil
      object.id = 'bar'
      expect(object.to_key).to be == ['bar']
    end

    it 'returns the model name' do
      expect(klass.model_name).to be == klass
    end

    describe 'param_key' do
      it 'converts :: to _' do
        stub_const 'Foo::Bar', klass
        expect(Foo::Bar.param_key).to be == 'foo_bar'
      end

      it 'converts title-case to snake-case' do
        stub_const 'UserRegistration', klass
        expect(UserRegistration.param_key).to be == 'user_registration'
      end
    end

    it 'returns the route_key' do
      stub_const 'Foo::Bar', klass
      expect(Foo::Bar.route_key).to be == 'foo_bars'
    end

    it 'returns the singular_route_key' do
      stub_const 'Foo::Bar', klass
      expect(Foo::Bar.singular_route_key).to be == 'foo_bar'
    end

    it 'returns the partial path' do
      stub_const 'Article', klass
      expect(Article.to_partial_path).to be == 'articles/_article'
    end

    describe 'human' do
      it 'returns the class name for a single-word class name' do
        stub_const 'Article', klass
        expect(Article.human).to be == 'Article'
      end

      it 'converts namespaced to capitalized words' do
        stub_const 'Foo::Bar', klass
        expect(Foo::Bar.human).to be == 'Foo Bar'
      end

      it 'separates title-cased words' do
        stub_const 'FooBarBaz', klass
        expect(FooBarBaz.human).to be == 'Foo Bar Baz'
      end

      it 'separates snake-cased, capitalized words' do
        stub_const 'FOO_BAR_BAZ', klass
        expect(FOO_BAR_BAZ.human).to be == 'Foo Bar Baz'
      end
    end
  end
end
