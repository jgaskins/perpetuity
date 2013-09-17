require 'perpetuity/postgres/query_union'
require 'perpetuity/postgres/query_intersection'

module Perpetuity
  class Postgres
    class QueryExpression
      attr_accessor :attribute, :comparator, :value
      def initialize attribute, comparator, value
        @attribute = attribute
        @comparator = comparator
        @value = value
      end

      def to_db
        public_send comparator
      end

      def sql_value
        if value.is_a? String or value.is_a? Symbol
          sanitized = value.to_s.gsub("'") { "\\'" }
          "'#{sanitized}'"
        elsif value.is_a? Regexp
          "'#{value.to_s.sub(/\A\(\?-mix\:/, '').sub(/\)\z/, '')}'"
        elsif value.is_a? Array
          "(#{value.join(',')})"
        else
          value
        end
      end

      def ==
        "#{attribute} = #{sql_value}"
      end

      def <
        "#{attribute} < #{sql_value}"
      end

      def <=
        "#{attribute} <= #{sql_value}"
      end

      def >
        "#{attribute} > #{sql_value}"
      end

      def >=
        "#{attribute} >= #{sql_value}"
      end

      def !=
        "#{attribute} != #{sql_value}"
      end

      def in
        "#{attribute} IN #{sql_value}"
      end

      def =~
        "#{attribute} ~ #{sql_value}"
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
