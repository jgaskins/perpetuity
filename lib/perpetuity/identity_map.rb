module Perpetuity
  class IdentityMap
    attr_reader :map

    def initialize
      @map = Hash.new { |hash, key| hash[key] = {} }
    end

    def [] klass, id
      map[klass][id]
    end

    def << object
      map[object.class][object.id] = object
    end
  end
end
