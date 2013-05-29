module Perpetuity
  class Reference
    attr_reader :klass, :id
    def initialize klass, id
      @klass = klass
      @id    = id
    end

    def == other
      if other.is_a? self.class
        klass == other.klass && id == other.id
      else
        other.is_a?(klass) && id == other.id
      end
    end

    def eql? other
      other.is_a?(self.class) && self == other
    end
  end
end
