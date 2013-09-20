require 'pg'

module Perpetuity
  class Postgres
    class Connection
      attr_reader :options

      def initialize options={}
        @options = sanitize_options(options)
      end

      def db
        options[:dbname]
      end

      def pg_connection
        @pg_connection ||= connect
      end

      def connect
        @pg_connection = PG.connect(options)
        use_uuid_extension

        @pg_connection
      rescue PG::ConnectionBad => e
        p e
        tries ||= 0
        conn = PG.connect
        conn.exec "CREATE DATABASE #{db}"
        conn.close

        if tries.zero?
          retry
        else
          raise e
        end
      end

      def active?
        !!@pg_connection
      end

      def execute sql
        pg_connection.exec sql
      end

      def tables
        sql = "SELECT table_name FROM information_schema.tables "
        sql << "WHERE table_schema = 'public'"

        result = execute(sql)
        result.to_a.map { |r| r['table_name'] }
      end

      def sanitize_options options
        options = options.dup
        db = options.delete(:db)
        username = options.delete(:username)

        if db
          options[:dbname] = db
        end

        if username
          options[:user] = username
        end

        options
      end

      private
      def use_uuid_extension
        @pg_connection.exec 'CREATE EXTENSION "uuid-ossp"'
      rescue PG::DuplicateObject
        # Ignore. It just means the extension's already been loaded.
      end
    end
  end
end
