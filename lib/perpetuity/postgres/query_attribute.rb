require 'perpetuity/postgres/query_expression'

module Perpetuity
  class Postgres
    class QueryAttribute
      attr_reader :name

      def initialize name
        @name = name
      end

      %w(!= <= < == > >= =~).each do |comparator|
        eval <<METHOD
        def #{comparator} value
          QueryExpression.new self, :#{comparator}, value
        end
METHOD
      end

      def in collection
        QueryExpression.new self, :in, collection
      end

      def to_s
        name.to_s
      end
    end
  end
end
