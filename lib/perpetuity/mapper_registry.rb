module Perpetuity
  class MapperRegistry
    def initialize
      @mappers = Hash.new { |_, klass| raise KeyError, "No mapper for #{klass}" }
    end

    def has_mapper? klass
      @mappers.has_key? klass
    end

    def [] klass
      @mappers[klass].new(self)
    end

    def []= klass, mapper
      @mappers[klass] = mapper
    end
  end
end
