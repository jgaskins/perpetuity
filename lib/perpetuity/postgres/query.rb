require 'perpetuity/postgres/query_attribute'

module Perpetuity
  class Postgres
    class Query
      attr_reader :query, :klass

      def initialize klass, &block
        @klass = klass
        @query = block
      end

      def to_db
        "SELECT * FROM #{klass} WHERE #{query.call(self).to_db}"
      end

      def method_missing name
        QueryAttribute.new(name)
      end
    end
  end
end
