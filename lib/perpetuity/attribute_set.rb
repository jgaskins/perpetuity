module Perpetuity
  class AttributeSet
    include Enumerable

    def initialize
      @attributes = {}
    end

    def << attribute
      @attributes[attribute.name] = attribute
    end

    def [] name
      @attributes[name]
    end

    def each &block
      @attributes.each_value(&block)
    end
  end
end
