require "perpetuity/version"
require "perpetuity/retrieval"
require "perpetuity/mongodb"
require "perpetuity/config"
require "perpetuity/mapper"

module Perpetuity
  def self.configure &block
    configuration.instance_exec(&block)
  end
  
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.generate_mapper_for klass, &block
    Mapper.generate_for klass, &block
  end

  def self.[] klass
    Mapper[klass]
  end
end
