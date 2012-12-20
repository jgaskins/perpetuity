module Perpetuity
  class MongoDB
    class Index
      KEY_ORDERS = { 1 => :ascending, -1 => :descending }
      attr_reader :attribute

      def initialize klass, attribute, options={}
        @attribute = attribute
        @unique = options.fetch(:unique) { false }
        @order = options.fetch(:order) { :ascending }
        @activated = false
      end

      def active?
        @activated
      end

      def inactive?
        !active?
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
end
