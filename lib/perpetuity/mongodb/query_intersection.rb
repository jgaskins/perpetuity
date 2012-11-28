module Perpetuity
  class MongoDB
    class QueryIntersection
      attr_reader :lhs, :rhs

      def initialize lhs, rhs
        @lhs = lhs
        @rhs = rhs
      end

      def to_db
        { '$and' => [lhs.to_db, rhs.to_db] }
      end
    end
  end
end
