module Perpetuity
  module Validations
    class Presence
      def initialize attribute
        @attribute = attribute
      end

      def pass? object
        !object.send(@attribute).nil? &&
        object.send(@attribute).strip != ''
      end
    end
  end
end
