require 'mongo'
require 'bson'

module Perpetuity
  class MongoDB
    def initialize options
      @host = options[:host] || 'localhost'
      @port = options[:port] || 27017
      @db = options[:db]
      @pool_size = options[:pool_size] || 5
      @username = options[:username]
      @password = options[:password]
      
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
      database.collection(klass.to_s).count()
    end

    def delete_all klass
      database.drop_collection klass.to_s
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

      database.collection(klass.to_s).find(criteria, other_options).sort(sort_criteria).each do |document|
        object = klass.allocate
        document.each_pair do |attribute,value|
          if object.respond_to?("#{attribute}=")
            object.send("#{attribute}=", value)
          else
            attribute = "@#{attribute}" unless attribute[0] == '@'
            object.instance_variable_set(attribute, value)
          end
        end
        objects << object
      end

      objects
    end

    def all klass
      retrieve klass, {}, {}
    end
    
    def delete object
      collection(object.class.to_s).remove "_id" => object.id
    end

    def update klass, id, new_data
      collection(klass).update({ _id: id }, new_data)
    end
  end
end
