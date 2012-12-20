module Perpetuity
  class Attribute
    attr_reader :name, :type
    def initialize(name, type, options = {})
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
  end
end
