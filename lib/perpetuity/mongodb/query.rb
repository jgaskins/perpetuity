require 'perpetuity/mongodb/query_attribute'

module Perpetuity
  class MongoDB
    class Query
      def initialize &block
        @query = block.call(self)
      end

      def to_db
        @query.to_db
      end

      def negate
        @query.negate
      end

      def method_missing missing_method
        QueryAttribute.new missing_method
      end
    end
  end
end
