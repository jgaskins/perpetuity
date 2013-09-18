require "perpetuity/version"
require "perpetuity/mongodb"
require "perpetuity/postgres"
require "perpetuity/config"
require "perpetuity/mapper"
require "perpetuity/mapper_registry"

module Perpetuity
  def self.configure &block
    detect_rails
    configuration.instance_exec(&block)
  end
  
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.generate_mapper_for klass, &block
    mapper = Class.new(Mapper)
    mapper.map klass, mapper_registry
    mapper.class_eval(&block) if block_given?
  end

  def self.[] klass
    mapper_registry[klass]
  end

  def self.mapper_registry
    @mapper_registry ||= MapperRegistry.new
  end

  def self.data_source adapter, db_name, options={}
    adapters = { mongodb: 'MongoDB', postgres: 'Postgres' }
    adapter_class = const_get(adapters[adapter])

    configure { data_source adapter_class.new(options.merge(db: db_name)) }
  end

  # Necessary to be able to check whether Rails is loaded and initialized
  def self.detect_rails
    require File.expand_path('../perpetuity/rails.rb', __FILE__) if defined? Rails
  end
end
