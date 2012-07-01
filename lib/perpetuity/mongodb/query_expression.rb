module Perpetuity
  class MongoDB
    class QueryExpression
      attr_accessor :comparator

      def initialize attribute, comparator, value
        @attribute = attribute
        @comparator = comparator
        @value = value

        @attribute = @attribute.to_sym if @attribute.respond_to? :to_sym
      end

      def to_db
        send @comparator
      end

      def equals
        { @attribute => @value }
      end

      def function func
        { @attribute => { func => @value } }
      end

      def less_than
        function '$lt'
      end

      def lte
        function '$lte'
      end

      def greater_than
        function '$gt'
      end

      def gte
        function '$gte'
      end

      def not_equal
        function '$ne'
      end

      def in
        function '$in'
      end

      def matches
        { @attribute => @value }
      end
    end
  end
end
