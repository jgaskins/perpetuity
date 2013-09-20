require 'perpetuity/postgres/connection'
require 'perpetuity/postgres/query'
require 'perpetuity/postgres/table'
require 'perpetuity/postgres/table/attribute'

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

    def insert data, mapper
      table = table_name(mapper.mapped_class)
      column_names = data.keys.join(',')
      values = data.values.map { |value| postgresify(value) }.join(',')
      sql = "INSERT INTO #{table} (#{column_names}) VALUES "
      sql << "(#{values}) RETURNING id"

      result = connection.execute(sql).to_a
      result.first['id']
    rescue PG::UndefinedTable # Table doesn't exist, so we need to create it.
      create_table_from_mapper mapper
    end

    def count klass
      table = table_name(klass)
      sql = "SELECT COUNT(*) FROM #{table}"
      connection.execute(sql).to_a.first['count'].to_i
    end

    def postgresify value
      if value.is_a? String
        "'#{value}'"
      elsif value == true || value == false
        value.to_s.upcase
      else
        value.to_s
      end
    end

    def find klass, id
      table = table_name(klass)
      id = postgresify(id)
      sql = "SELECT * FROM #{table} WHERE id = #{id}"
      connection.execute(sql).to_a.first
    end

    def table_name klass
      klass.to_s.inspect
    end

    def query klass, &block
      Query.new(klass, &block)
    end

    def negate_query
    end

    def retrieve klass, criteria, options={}
    end

    def drop_table name
      connection.execute "DROP TABLE IF EXISTS #{name.inspect}"
    end

    def create_table name, attributes
      connection.execute Table.new(name, attributes).create_table_sql
    end

    def has_table? name
      connection.tables.include? name
    end

    def serialize object, mapper
      Serializer.new(mapper).serialize object
    end

    def unserialize data, mapper
    end

    def create_table_from_mapper mapper
      attributes = mapper.attribute_set.map do |attr|
        name = attr.name
        type = attr.type
        options = attr.options
        Table::Attribute.new name, type, options
      end
      create_table mapper.mapped_class.to_s, attributes
    end
  end
end
