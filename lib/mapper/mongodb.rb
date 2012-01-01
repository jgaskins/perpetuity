require 'mongo'
require 'bson'

class Mapper
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
      @connection = Mongo::Connection.new @host, @port, pool_size: @pool_size
    end
    
    def database
      @connection.db(@db)
    end
    
    def collection klass
      database.collection klass.to_s
    end
    
    def insert object
      mapper = Mapper.new object
      collection(object.class).insert mapper.object_attributes
    end
    
    def count klass
      database.collection(klass.to_s).count()
    end
    
    def delete klass
      database.drop_collection klass.to_s
    end
    
    def retrieve klass, criteria
      objects = []
      if criteria.has_key?(:id)
        criteria[:_id] = criteria[:id]
        criteria.delete :id
      end
      database.collection(klass.to_s).find(criteria).each do |document|
        object = klass.allocate
        document.each_pair do |k,v|
          k = '@_id' if k == '_id'
          object.instance_variable_set(k, v)
        end
        objects << object
      end
      
      objects
    end
    
    def all klass
      retrieve klass, {}
    end
  end
end