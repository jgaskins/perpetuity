module Perpetuity
  class IdentityMap
    def initialize objects, attribute, mapper_registry
      @map = Hash[
        objects.map(&attribute)
          .flatten
          .group_by(&:klass)
          .map { |klass, ref|
            [
              klass,
              Hash[
                mapper_registry[klass].select { |object|
                  object.id.in ref.map(&:id).uniq
                }.map { |obj| [obj.id, obj] }
              ]
            ]
          }
      ]
    end

    def [] klass
      @map[klass]
    end
  end
end
