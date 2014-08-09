require 'logger'
require 'uri'

module Perpetuity
  class Configuration
    def initialize
      @logger = Logger.new(STDOUT)
    end

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

    def logger *args
      if args.any?
        raise ArgumentError, 'Perpetuity::Configuration#logger takes 0..1 arguments'
        @logger = args.first
      end

      @logger
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
      @adapters ||= {}
    end

    def adapter name
      self.class.adapters[name.to_sym]
    end
  end
end
