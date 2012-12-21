require 'mongo'
require 'perpetuity/mongodb/query'
require 'perpetuity/mongodb/index'

module Perpetuity
  class MongoDB
    attr_accessor :connection, :host, :port, :db, :pool_size, :username, :password

    def initialize options
      @host       = options.fetch(:host, 'localhost')
      @port       = options.fetch(:port, 27017)
      @db         = options.fetch(:db)
      @pool_size  = options.fetch(:pool_size, 5)
      @username   = options[:username]
      @password   = options[:password]
      @connection = nil
      @indexes    = Hash.new { |hash, key| hash[key] = active_indexes(key) }
    end

    def connect
      database.authenticate(@username, @password) if @username and @password
      @connection ||= Mongo::MongoClient.new @host, @port, pool_size: @pool_size
    end

    def connected?
      !!@connection
    end

    def database
      connect unless connected?
      @connection.db(@db)
    end

    def collection klass
      database.collection(klass.to_s)
    end

    def insert klass, attributes
      if attributes.has_key? :id
        attributes[:_id] = attributes[:id]
        attributes.delete :id
      end

      collection(klass).insert attributes
    end

    def count klass
      collection(klass).count
    end

    def delete_all klass
      database.collection(klass.to_s).remove
    end

    def first klass
      document = database.collection(klass.to_s).find_one
      document[:id] = document.delete("_id")

      document
    end

    def retrieve klass, criteria, options = {}
      objects = []

      # MongoDB uses '_id' as its ID field.
      if criteria.has_key?(:id)
        criteria = {
          '$or' => [
            { _id: BSON::ObjectId.from_string(criteria[:id].to_s) },
            { _id: criteria[:id].to_s }
          ]
        }
      end

      sort_field = options[:attribute]
      sort_direction = options[:direction]
      sort_criteria = [[sort_field, sort_direction]]
      other_options = { limit: options[:limit] }
      if options[:page]
        other_options = other_options.merge skip: (options[:page] - 1) * options[:limit]
      end

      database.collection(klass.to_s).find(criteria, other_options).sort(sort_criteria).each do |document|
        document[:id] = document.delete("_id")
        objects << document
      end

      objects
    end

    def all klass
      retrieve klass, {}, {}
    end
    
    def delete object, klass=nil
      id = object.respond_to?(:id) ? object.id : object
      klass ||= object.class
      collection(klass.to_s).remove "_id" => id
    end

    def update klass, id, new_data
      collection(klass).update({ _id: id }, new_data)
    end

    def can_serialize? value
      serializable_types.include? value.class
    end

    def drop_collection to_be_dropped
      collection(to_be_dropped).drop
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
      indexes = collection(klass).index_information
      indexes.map do |name, index|
        key = index['key'].keys.first
        direction = index['key'][key]
        unique = index['unique']
        Index.new(klass, key, order: Index::KEY_ORDERS[direction], unique: unique)
      end
    end

    def activate_index! index
      attribute = index.attribute.to_s
      order = index.order == :ascending ? 1 : -1
      unique = index.unique?

      collection(index.collection).create_index [[attribute, order]], unique: unique
      index.activate!
    end

    private
    def serializable_types
      @serializable_types ||= [NilClass, TrueClass, FalseClass, Fixnum, Float, String, Array, Hash, Time]
    end
  end
end
