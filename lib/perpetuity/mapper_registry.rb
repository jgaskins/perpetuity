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
      mapper_class(klass).new(self)
    end

    def mapper_for klass, options={}
      identity_map = options.fetch(:identity_map) { IdentityMap.new }
      mapper_class(klass).new(self, identity_map)
    end

    def mapper_class klass
      @mappers.fetch(klass) do
        load_mappers
        unless @mappers.has_key? klass
          raise KeyError, "No mapper for #{klass}"
        end
        @mappers[klass]
      end
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
