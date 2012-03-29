module Perpetuity
  class AttributeSet
    include Enumerable

    def initialize
      @attributes = []
    end

    def << attribute
      @attributes << attribute
    end

    def each &block
      @attributes.each(&block)
    end

    def [] name
      @attributes.find { |attr| attr.name == name }
    end
  end
end
