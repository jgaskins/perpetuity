require 'set'

module Perpetuity
  class AttributeSet < Set
    def [] name
      find { |attr| attr.name == name }
    end
  end
end
