module Perpetuity
  module Rails
    class MapperReloader
      attr_reader :app

      def initialize app
        @app = app
      end

      def call env
        if mapped_classes_updated? or no_mappers_loaded?
          mapper_files.each(&method(:load))
        end

        app.call env
      end

      def mapper_files
        Dir['app/**/*_mapper.rb']
      end

      def mapped_classes_updated?
        Perpetuity.mapper_registry.each do |klass, mapper|
          return true unless Object.const_get(klass.name) == klass
        end
        false
      end

      def no_mappers_loaded?
        Perpetuity.mapper_registry.none?
      end
    end
  end
end
