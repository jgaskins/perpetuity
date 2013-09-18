module Perpetuity
  class Postgres
    class Table
      attr_reader :name, :attributes
      def initialize name, attributes
        @name = name
        @attributes = attributes
      end

      def create_table_sql
        sql = "CREATE TABLE #{name} ("
        sql << attributes.map { |a| "#{a.name} #{a.sql_type}" }.join(', ')
        sql << ')'
      end
    end
  end
end
