$:.unshift('lib').uniq!
require 'perpetuity/data_injectable'

module Perpetuity
  class InjectableClass
    extend DataInjectable
  end

  describe DataInjectable do
    let(:klass) { InjectableClass }
    let(:object) { klass.new }

    it 'injects data into an object' do
      klass.inject_data object, { a: 1, b: 2 }
      object.instance_variable_get(:@a).should == 1
      object.instance_variable_get(:@b).should == 2
    end

    it 'injects an id' do
      klass.inject_data object, { id: 1 }
      object.id.should == 1
    end

    it 'injects a specified id' do
      klass.give_id_to object, 2
      object.id.should == 2
    end
  end
end
