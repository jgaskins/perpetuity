module Perpetuity
  class Attribute
    attr_reader :name, :type
    def initialize(name, type=nil, options = {})
      @name = name
      @type = type

      options.each do |option, value|
        instance_variable_set "@#{option}", value
      end
    end

    def embedded?
      @embedded ||= false
    end

    def to_s
      name
    end

    def =~ regexp
      name.to_s =~ regexp
    end
  end
end
