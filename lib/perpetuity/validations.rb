module Perpetuity
  class ValidationSet < Set

    def valid? object
      each do |validation|
        return false unless validation.pass?(object)
      end

      true
    end

    def invalid? object
      !valid? object
    end

    def present attribute
      self << Perpetuity::Validations::Presence.new(attribute)
    end

    def length attribute, options = {}
      self << Perpetuity::Validations::Length.new(attribute, options)
    end
  end

  module Validations
    class Presence
      def initialize attribute
        @attribute = attribute
      end

      def pass? object
        !object.send(@attribute).nil?
      end
    end

    class Length
      def initialize attribute, options
        @attribute = attribute
        @options = options
      end

      def pass? object
        length = object.send(@attribute).length

        return false unless @options[:at_least].nil? or @options[:at_least] <= length
        return false unless @options[:at_most].nil? or @options[:at_most] >= length

        true
      end
    end
  end
end
