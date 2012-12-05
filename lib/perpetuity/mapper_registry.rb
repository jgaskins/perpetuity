module Perpetuity
  class MapperRegistry
    @mappers = Hash.new { |_, klass| raise KeyError, "No mapper for #{klass}" }

    def self.has_mapper? klass
      @mappers.has_key? klass
    end

    def self.[] klass
      @mappers[klass].new
    end

    def self.[]= klass, mapper
      @mappers[klass] = mapper
    end
  end
end
