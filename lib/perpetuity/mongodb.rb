require 'moped'
require 'perpetuity/mongodb/query'
require 'perpetuity/mongodb/index'
require 'perpetuity/mongodb/serializer'
require 'set'
require 'perpetuity/exceptions/duplicate_key_error'

module Perpetuity
  class MongoDB
    attr_accessor :host, :port, :db, :pool_size, :username, :password

    def initialize options
      @host       = options.fetch(:host, 'localhost')
      @port       = options.fetch(:port, 27017)
      @db         = options.fetch(:db)
      @pool_size  = options.fetch(:pool_size, 5)
      @username   = options[:username]
      @password   = options[:password]
      @session    = nil
      @indexes    = Hash.new { |hash, key| hash[key] = active_indexes(key) }
      @connected  = false
    end

    def session
      @session ||= Moped::Session.new(["#{host}:#{port}"]).with(safe: true)
    end

    def connect
      session.login(@username, @password) if @username and @password
      @connected = true
      session
    end

    def connected?
      !!@connected
    end

    def database
      session.use db
      connect unless connected?
      session
    end

    def collection klass
      database[klass.to_s]
    end

    def insert klass, attributes
      if attributes.has_key? :id
        attributes[:_id] = attributes[:id]
        attributes.delete :id
      else
        attributes[:_id] = Moped::BSON::ObjectId.new
      end

      collection(klass).insert attributes
      attributes[:_id]
    rescue Moped::Errors::OperationFailure => e
      if e.message =~ /duplicate key/
        e.message =~ /\$(\w+)_\d.*dup key: { : (.*) }/
        key = $1
        value = $2.gsub("\\\"", "\"")
        raise DuplicateKeyError, "Tried to insert #{klass} with duplicate unique index: #{key} => #{value}"
      end
    end

    def count klass
      collection(klass).find.count
    end

    def delete_all klass
      collection(klass.to_s).find.remove_all
    end

    def first klass
      document = collection(klass.to_s).find.limit(1).first
      document[:id] = document.delete("_id")

      document
    end

    def retrieve klass, criteria, options = {}
      # MongoDB uses '_id' as its ID field.
      criteria = to_bson_id(criteria)

      query = collection(klass.to_s).find(criteria)

      skipped = options[:page] ? (options[:page] - 1) * options[:limit] : 0
      query = query.skip skipped
      query = query.limit(options[:limit])
      query = sort(query, options)

      query.map do |document|
        document[:id] = document.delete("_id")
        document
      end
    end

    def convert_to_bson_id criteria
      criteria = criteria.dup
      if criteria.has_key?(:id)
        if criteria[:id].is_a? String
          criteria = { _id: (Moped::BSON::ObjectId(criteria[:id].to_s) rescue criteria[:id]) }
        else
          criteria[:_id] = criteria.delete(:id)
        end
      end

      criteria
    end

    def sort query, options
      return query unless options[:attribute] &&
                          options[:direction]

      sort_orders = { ascending: 1, descending: -1 }
      sort_field = options[:attribute]
      sort_direction = options[:direction]
      sort_criteria = { sort_field => sort_orders[sort_direction] }
      query.sort(sort_criteria)
    end

    def all klass
      retrieve klass, {}, {}
    end
    
    def delete object_or_id, klass=nil
      id = object_or_id.is_a?(PersistedObject) ? object_or_id.id : object_or_id
      klass ||= object.class
      collection(klass.to_s).find("_id" => id).remove
    end

    def update klass, id, new_data
      collection(klass).find({ _id: id }).update(new_data)
    end

    def can_serialize? value
      serializable_types.include? value.class
    end

    def drop_collection to_be_dropped
      collection(to_be_dropped.to_s).drop
    end

    def query &block
      Query.new(&block)
    end

    def index klass, attribute, options={}
      @indexes[klass] ||= Set.new

      index = Index.new(klass, attribute, options)
      @indexes[klass] << index 
      index
    end

    def indexes klass
      @indexes[klass]
    end

    def active_indexes klass
      indexes = collection(klass).indexes.to_a
      indexes.map do |index|
        key = index['key'].keys.first
        direction = index['key'][key]
        unique = index['unique']
        Index.new(klass, key, order: Index::KEY_ORDERS[direction], unique: unique)
      end.to_set
    end

    def activate_index! index
      attribute = index.attribute.to_s
      order = index.order == :ascending ? 1 : -1
      unique = index.unique?

      collection(index.collection).indexes.create({attribute => order}, unique: unique)
      index.activate!
    end

    def remove_index index
      coll = collection(index.collection)
      db_indexes = coll.indexes.select do |db_index|
        db_index['name'] =~ /\A#{index.attribute}/
      end.map { |index| index['key'] }

      if db_indexes.any?
        collection(index.collection).indexes.drop db_indexes.first
      end
    end

    def serialize object, mapper
      Serializer.new(mapper).serialize object
    end

    def unserialize data, mapper
      Serializer.new(mapper).unserialize data
    end

    private
    def serializable_types
      @serializable_types ||= [NilClass, TrueClass, FalseClass, Fixnum, Float, String, Array, Hash, Time]
    end
  end
end
