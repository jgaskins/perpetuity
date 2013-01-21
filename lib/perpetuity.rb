require "perpetuity/version"
require "perpetuity/retrieval"
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
    mapper.instance_exec &block if block_given?
  end

  def self.[] klass
    mapper_registry[klass]
  end

  def self.mapper_registry
    @mapper_registry ||= MapperRegistry.new
  end
end
