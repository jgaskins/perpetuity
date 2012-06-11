require 'mongo'
require 'bson'

module Perpetuity
  class MongoDB
    def initialize options
      @host      = options.fetch(:host, 'localhost')
      @port      = options.fetch(:port, 27017)
      @db        = options.fetch(:db)
      @pool_size = options.fetch(:pool_size, 5)
      @username  = options[:username]
      @password  = options[:password]
      
      connect
      database.authenticate(@username, @password) if @username and @password
    end

    def connect
      @connection ||= Mongo::Connection.new @host, @port, pool_size: @pool_size
    end

    def database
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
      database.collection(klass.to_s).count
    end

    def delete_all klass
      database.collection(klass.to_s).remove
    end

    def first klass
      data = database.collection(klass.to_s).find_one
      object = klass.allocate
      inject_data object, data

      object
    end

    def retrieve klass, criteria, options = {}
      objects = []

      # MongoDB uses '_id' as its ID field.
      if criteria.has_key?(:id)
        criteria[:_id] = criteria[:id]
        criteria.delete :id
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
  end
end
