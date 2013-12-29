module Perpetuity
  class Attribute
    attr_reader :name, :type
    def initialize(name, type=nil, options = {})
      @name = name
      @type = type

      @_options = options.dup
      options.each do |option, value|
        instance_variable_set "@#{option}", value
      end
    end

    def options option=nil
      if option
        instance_variable_get("@#{option}")
      else
        @_options
      end
    end

    def embedded?
      @embedded ||= false
    end

    def to_s
      name.to_s
    end

    def =~ regexp
      name.to_s =~ regexp
    end

    def == other
      other.is_a?(self.class) &&
      name.to_s == other.name.to_s
    end
  end
end
