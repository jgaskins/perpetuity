require 'perpetuity/postgres/query_union'

module Perpetuity
  class Postgres
    class QueryIntersection
      attr_reader :lhs, :rhs

      def initialize lhs, rhs
        @lhs = lhs
        @rhs = rhs
      end

      def to_db
        "(#{lhs.to_db} AND #{rhs.to_db})"
      end

      def & other
        QueryIntersection.new(self, other)
      end

      def | other
        QueryUnion.new(self, other)
      end
    end
  end
end
