require 'uri'

module Perpetuity
  class Configuration
    def data_source *args
      if args.any?
        db = args.first

        case db
        when String
          args[0] = URI(args[0])
          @db = data_source_from_url(*args)
        when Symbol
          adapter = args.shift
          db_name = args.shift
          options = args.shift || {}
          adapter_class = adapter(adapter)

          @db = adapter_class.new(options.merge(db: db_name))
        end
      end

      @db
    end

    def data_source_from_url *args
      uri = args.shift
      options = args.shift || {}

      protocol = uri.scheme
      klass = adapter(protocol)
      db_options = {
        db: uri.path[1..-1],
        username: uri.user,
        password: uri.password,
        host: uri.host,
        port: uri.port,
      }
      if options.key? :pool_size
        db_options[:pool_size] = options[:pool_size]
      end

      klass.new(db_options)
    end

    def self.adapters
      if @adapters.nil?
        @adapters = {}
        @adapters[:dynamodb] = Perpetuity::DynamoDB if defined?(Perpetuity::DynamoDB)
        @adapters[:mongodb] = Perpetuity::MongoDB if defined?(Perpetuity::MongoDB)
        @adapters[:postgres] = Perpetuity::Postgres if defined?(Perpetuity::Postgres)
      end
      @adapters
    end

    def adapter name
      self.class.adapters[name.to_sym]
    end
  end
end
