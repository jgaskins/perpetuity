require 'set'

module Perpetuity
  class AttributeSet
    include Enumerable

    def initialize
      @attributes = Set.new
    end

    def << attribute
      @attributes << attribute
    end

    def [] name
      @attributes.find { |attr| attr.name == name }
    end

    def each &block
      @attributes.each &block
    end
  end
end
