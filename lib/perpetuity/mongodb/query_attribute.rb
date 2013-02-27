require 'perpetuity/mongodb/query_expression'

module Perpetuity
  class MongoDB
    class QueryAttribute
      attr_reader :name

      def initialize name
        @name = name
      end

      def == value
        QueryExpression.new self, :equals, value
      end

      def < value
        QueryExpression.new self, :less_than, value
      end

      def >= value
        QueryExpression.new self, :gte, value
      end

      def > value
        QueryExpression.new self, :greater_than, value
      end

      def <= value
        QueryExpression.new self, :lte, value
      end

      def != value
        QueryExpression.new self, :not_equal, value
      end
      alias :not_equal? :'!='

      def =~ regexp
        QueryExpression.new self, :matches, regexp
      end

      def in collection
        QueryExpression.new self, :in, collection
      end

      def to_sym
        name
      end
    end
  end
end
