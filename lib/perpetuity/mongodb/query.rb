require 'perpetuity/mongodb/query_attribute'
require 'perpetuity/mongodb/nil_query'

module Perpetuity
  class MongoDB
    class Query
      attr_reader :query
      def initialize &block
        if block_given?
          @query = block.call(self)
        else
          @query = NilQuery.new
        end
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

      def == other
        query == other.query
      end
    end
  end
end
