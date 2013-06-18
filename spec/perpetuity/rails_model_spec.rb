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
      object.to_param.should == nil
      object.id = 'foo'
      object.to_param.should == 'foo'
    end

    it 'returns the keys on the object' do
      object.to_key.should == nil
      object.id = 'bar'
      object.to_key.should == ['bar']
    end

    it 'returns the model name' do
      klass.model_name.should == klass
    end

    it 'returns the param_key' do
      stub_const 'Foo::Bar', klass
      Foo::Bar.param_key.should == 'foo_bar'
    end

    it 'returns the route_key' do
      stub_const 'Foo::Bar', klass
      Foo::Bar.route_key.should == 'foo_bars'
    end

    it 'returns the singular_route_key' do
      stub_const 'Foo::Bar', klass
      Foo::Bar.singular_route_key.should == 'foo_bar'
    end
  end
end
