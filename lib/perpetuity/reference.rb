module Perpetuity
  class Reference
    attr_reader :klass, :id
    def initialize klass, id
      @klass = klass
      @id    = id
    end

    def == other
      klass == other.klass && id == other.id
    end

    def eql? other
      self == other
    end
  end
end
