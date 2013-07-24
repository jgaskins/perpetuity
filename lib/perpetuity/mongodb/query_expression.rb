require 'perpetuity/mongodb/query_union'
require 'perpetuity/mongodb/query_intersection'

module Perpetuity
  class MongoDB
    class QueryExpression
      attr_accessor :attribute, :comparator, :negated, :value

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
        f = { func => @value }

        if @negated
          { @attribute => { '$not' => f } }
        else
          { @attribute => f }
        end
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
        if @negated
          { @attribute => { '$not' => @value } }
        else
          { @attribute => @value }
        end
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

      def == other
        attribute == other.attribute &&
        comparator == other.comparator &&
        value == other.value &&
        negated == other.negated
      end
    end
  end
end
