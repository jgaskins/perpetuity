require 'perpetuity/identity_map'

module Perpetuity
  class Dereferencer
    attr_reader :map, :mapper_registry

    def initialize mapper_registry
      @map = IdentityMap.new
      @mapper_registry = mapper_registry
    end

    def load references
      references = Array(references).flatten

      references.group_by(&:klass).map { |klass, refs|
        objects klass, refs.map(&:id)
      }.flatten.each { |object| map << object }
    end

    def [] reference
      map[reference.klass, reference.id]
    end

    def objects klass, ids
      mapper_registry[klass].select { |object|
        object.id.in ids.uniq
      }.to_a
    end
  end
end
