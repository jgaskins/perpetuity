module Perpetuity
  class Index
    attr_reader :attribute

    def initialize attribute, options={}
      @attribute = attribute
      @unique = options.fetch(:unique) { false }
      @order = options.fetch(:order) { :ascending }
      @activated = false
    end

    def active?
      @activated
    end

    def activate!
      @activated = true
    end

    def unique?
      @unique
    end

    def order
      @order
    end
  end
end
