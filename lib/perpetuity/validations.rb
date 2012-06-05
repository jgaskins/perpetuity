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
        options.each do |option, value|
          send option, value
        end
      end

      def pass? object
        length = object.send(@attribute).length

        return false unless @at_least.nil? or @at_least <= length
        return false unless @at_most.nil? or @at_most >= length

        true
      end

      def at_least value
        @at_least = value
      end

      def at_most value
        @at_most = value
      end

      def between range
        at_least range.min
        at_most range.max
      end
    end
  end
end
