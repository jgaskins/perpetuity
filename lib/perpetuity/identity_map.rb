module Perpetuity
  class IdentityMap
    def initialize
      @map = Hash.new { |hash, key| hash[key] = {} }
    end

    def [] klass, id
      @map[klass][id]
    end

    def << object
      klass = object.class
      id = object.instance_variable_get(:@id)
      @map[klass][id] = object
    end
  end
end
