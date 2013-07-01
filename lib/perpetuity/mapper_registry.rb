module Perpetuity
  class MapperRegistry
    include Enumerable

    def initialize
      @mappers = Hash.new
    end

    def has_mapper? klass
      @mappers.has_key? klass
    end

    def [] klass
      mapper_class = @mappers.fetch(klass) do
        load_mappers
        unless @mappers.has_key? klass
          raise KeyError, "No mapper for #{klass}"
        end
        @mappers[klass]
      end

      mapper_class.new(self)
    end

    def []= klass, mapper
      @mappers[klass] = mapper
    end

    def each &block
      @mappers.each(&block)
    end

    def load_mappers
      check_rails_app_for_mappers.each(&method(:load))
    end

    def check_rails_app_for_mappers
      Dir['app/**/*_mapper.rb']
    end
  end
end
