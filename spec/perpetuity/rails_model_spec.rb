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
      object.should_not be_persisted
      object.id = 'lol'
      object.should be_persisted
    end

    it 'returns the id as to_param' do
      object.to_param.should be == nil
      object.id = 'foo'
      object.to_param.should be == 'foo'
    end

    it 'returns the keys on the object' do
      object.to_key.should be == nil
      object.id = 'bar'
      object.to_key.should be == ['bar']
    end

    it 'returns the model name' do
      klass.model_name.should be == klass
    end

    describe 'param_key' do
      it 'converts :: to _' do
        stub_const 'Foo::Bar', klass
        Foo::Bar.param_key.should be == 'foo_bar'
      end

      it 'converts title-case to snake-case' do
        stub_const 'UserRegistration', klass
        UserRegistration.param_key.should be == 'user_registration'
      end
    end

    it 'returns the route_key' do
      stub_const 'Foo::Bar', klass
      Foo::Bar.route_key.should be == 'foo_bars'
    end

    it 'returns the singular_route_key' do
      stub_const 'Foo::Bar', klass
      Foo::Bar.singular_route_key.should be == 'foo_bar'
    end

    it 'returns the partial path' do
      stub_const 'Article', klass
      Article.to_partial_path.should be == 'articles/_article'
    end
  end
end
