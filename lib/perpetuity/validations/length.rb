module Perpetuity
  module Validations
    class Length
      def initialize attribute, options
        @attribute = attribute
        @at_least  = nil
        @at_most   = nil
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
