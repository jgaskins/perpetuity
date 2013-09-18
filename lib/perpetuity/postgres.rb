require 'perpetuity/postgres/connection'
require 'perpetuity/postgres/query'
require 'perpetuity/postgres/table'

module Perpetuity
  class Postgres
    attr_reader :host, :port, :db, :pool_size, :username, :password,
                :connection

    def initialize options
      @host      = options.fetch(:host) { 'localhost' }
      @port      = options.fetch(:port) { 5432 }
      @db        = options.fetch(:db)
      @pool_size = options.fetch(:pool_size) { 5 }
      @username  = options.fetch(:username) { ENV['USER'] }
      @password  = options.fetch(:password) {}

      @connection ||= Connection.new(
        db:       db,
        host:     host,
        port:     port,
        username: username,
        password: password,
      )
    end

    def insert klass, data
      []
    end

    def query klass, &block
      Query.new(klass, &block)
    end

    def negate_query
    end

    def retrieve klass, criteria, options={}
    end

    def drop_table name
      connection.execute "DROP TABLE IF EXISTS #{name}"
    end

    def create_table name, attributes
      connection.execute Table.new(name, attributes).create_table_sql
    end

    def has_table? name
      connection.tables.include? name.downcase
    end

    def serialize object, mapper
      Serializer.new(mapper).serialize object
    end

    def unserialize data, mapper
    end
  end
end
