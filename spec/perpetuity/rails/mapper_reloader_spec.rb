require 'perpetuity/rails/mapper_reloader'

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

      it 'loads mapper files' do
        reloader.should_receive(:load).with('foo_mapper.rb')
        reloader.call env
      end

      it 'passes on to the next rack app' do
        reloader.stub :load
        app.should_receive(:call).with env
        reloader.call env
      end
    end
  end
end
