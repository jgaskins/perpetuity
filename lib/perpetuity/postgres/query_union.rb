require 'perpetuity/postgres/query_intersection'

module Perpetuity
  class Postgres
    class QueryUnion
      attr_reader :lhs, :rhs

      def initialize lhs, rhs
        @lhs = lhs
        @rhs = rhs
      end

      def to_db
        "(#{lhs.to_db} OR #{rhs.to_db})"
      end

      def | other
        QueryUnion.new(self, other)
      end

      def & other
        QueryIntersection.new(self, other)
      end
    end
  end
end
