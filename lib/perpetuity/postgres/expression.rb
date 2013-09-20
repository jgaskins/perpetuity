module Perpetuity
  class Postgres
    class Expression
      def initialize string
        @string = string
      end

      def to_sql
        @string
      end

      def to_s
        @string
      end

      def == other
        other.is_a?(self.class) && to_sql == other.to_sql
      end
    end
  end
end
