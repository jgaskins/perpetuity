require 'perpetuity/identity_map'
require 'perpetuity/reference'

module Perpetuity
  class Dereferencer
    attr_reader :map, :mapper_registry

    def initialize mapper_registry, identity_map=IdentityMap.new
      @map = identity_map
      @mapper_registry = mapper_registry
    end

    def load references
      references = Array(references).flatten.select {|ref| referenceable?(ref) }

      cache grouped(references).map { |klass, refs|
        objects klass, refs.map(&:id)
      }.flatten
    end

    def cache objects
      objects.each { |object| map << object }
    end

    def [] reference
      if referenceable?(reference)
        map[reference.klass, reference.id]
      else
        reference
      end
    end

    def grouped references
      references.group_by(&:klass)
    end

    def objects klass, ids
      ids = ids.uniq
      if ids.one?
        mapper_registry.mapper_for(klass, identity_map: map).find(ids.first)
      elsif ids.none?
        []
      else
        mapper_registry[klass].find(ids.uniq).to_a
      end
    end

    def referenceable? ref
      [:klass, :id].all? { |msg| ref.respond_to?(msg) }
    end
  end
end
