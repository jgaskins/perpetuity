module Perpetuity
  class MongoDB
    class Index
      KEY_ORDERS = { 1 => :ascending, -1 => :descending }
      attr_reader :collection, :attribute

      def initialize klass, attribute, options={}
        @collection = klass
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

      def == other
        hash == other.hash
      end

      def eql? other
        self == other
      end

      def attribute_name
        attribute.respond_to?(:name) ? attribute.name : attribute
      end

      def hash
        "#{collection}/#{attribute_name}:#{unique?}:#{order}".hash
      end
    end
  end
end
