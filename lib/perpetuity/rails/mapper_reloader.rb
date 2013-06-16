module Perpetuity
  module Rails
    class MapperReloader
      attr_reader :app

      def initialize app
        @app = app
      end

      def call env
        mapper_files.each(&method(:load))
        app.call env
      end

      def mapper_files
        Dir['app/**/*_mapper.rb']
      end
    end
  end
end
