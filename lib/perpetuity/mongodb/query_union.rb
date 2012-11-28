module Perpetuity
  class MongoDB
    class QueryUnion
      attr_reader :lhs, :rhs

      def initialize lhs, rhs
        @lhs = lhs
        @rhs = rhs
      end

      def to_db
        { '$or' => [lhs.to_db, rhs.to_db] }
      end
    end
  end
end
