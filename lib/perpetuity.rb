require "perpetuity/version"
require "perpetuity/mongodb"
require "perpetuity/config"
require "perpetuity/mapper"
require "perpetuity/mapper_registry"

module Perpetuity
  def self.configure &block
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
    adapters = { mongodb: MongoDB }

    configure { data_source adapters[adapter].new(options.merge(db: db_name)) }
  end
end
