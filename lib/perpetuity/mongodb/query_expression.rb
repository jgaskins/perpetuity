require 'perpetuity/mongodb/query_union'
require 'perpetuity/mongodb/query_intersection'

module Perpetuity
  class MongoDB
    class QueryExpression
      attr_accessor :comparator, :negated

      def initialize attribute, comparator, value
        @attribute = attribute
        @comparator = comparator
        @value = value
        @negated = false

        @attribute = @attribute.to_sym if @attribute.respond_to? :to_sym
      end

      def to_db
        public_send @comparator
      end

      def equals
        if @negated
          { @attribute => { '$ne' => @value } }
        else
          { @attribute => @value }
        end
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

      def | other
        QueryUnion.new(self, other)
      end

      def & other
        QueryIntersection.new(self, other)
      end

      def negate
        expr = dup
        expr.negated = true
        expr
      end
    end
  end
end
