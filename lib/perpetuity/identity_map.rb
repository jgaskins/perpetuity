module Perpetuity
  class IdentityMap
    attr_reader :map, :mapper_registry

    def initialize mapper_registry=Perpetuity.mapper_registry
      @map = Hash.new { |hash, key| hash[key] = {} }
      @mapper_registry = mapper_registry
    end

    def [] klass, id
      map[klass][id.to_s]
    end

    def << object
      klass = object.class
      id = mapper_registry[klass].id_for(object)
      map[klass][id.to_s] = object
    end
  end
end
