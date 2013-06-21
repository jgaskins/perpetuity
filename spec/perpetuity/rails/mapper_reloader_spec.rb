require 'support/stubbed_rails'
require 'perpetuity'
require 'perpetuity/rails'

module Perpetuity
  module Rails
    describe MapperReloader do
      let(:app) { double('Rack app', call: nil) }
      let(:reloader) { MapperReloader.new(app) }
      let(:env) { {} }

      before do
        Dir.stub(:[]).with('app/**/*_mapper.rb') { ['foo_mapper.rb'] }
      end

      it 'finds mapper files' do
        reloader.mapper_files.should == ['foo_mapper.rb']
      end

      it 'loads mapper files if mappers have been updated' do
        reloader.stub mapped_classes_updated?: true
        reloader.should_receive(:load).with('foo_mapper.rb')
        reloader.call env
      end

      it 'loads mapper files if no mappers are loaded' do
        reloader.stub no_mappers_loaded?: true
        reloader.should_receive(:load).with('foo_mapper.rb')
        reloader.call env
      end

      it 'does not load mapper files if mappers have not been updated' do
        reloader.stub mapped_classes_updated?: false
        reloader.stub no_mappers_loaded?: false
        reloader.should_not_receive(:load).with('foo_mapper.rb')
        reloader.call env
      end

      it 'passes on to the next rack app' do
        reloader.stub :load
        app.should_receive(:call).with env
        reloader.call env
      end

      it 'checks whether the mapped classes have changed' do
        reloader.stub :load
        user_mapper = Class.new
        stub_const 'User', Class.new
        Perpetuity.stub mapper_registry: {User => user_mapper}

        expect(reloader.mapped_classes_updated?).to be_false

        stub_const 'User', Class.new

        expect(reloader.mapped_classes_updated?).to be_true
      end
    end
  end
end
