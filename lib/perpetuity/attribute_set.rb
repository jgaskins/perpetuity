module Perpetuity
  class AttributeSet
    include Enumerable

    def initialize *attributes
      @attributes = {}
      attributes.each do |attribute|
        self << attribute
      end
    end

    def << attribute
      @attributes[attribute.name] = attribute
      self
    end

    def [] name
      @attributes[name]
    end

    def each &block
      @attributes.each_value(&block)
    end
  end
end
