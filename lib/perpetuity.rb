require "perpetuity/version"
require "perpetuity/config"
require "perpetuity/mapper"
require "perpetuity/mapper_registry"

module Perpetuity
  def self.configure &block
    register_standard_adapters
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

  def self.data_source *args
    configure { data_source *args }
  end

  def self.register_adapter adapters
    config_adapters = Perpetuity::Configuration.adapters
    adapters.each do |adapter_name, adapter_class|
      if config_adapters.has_key?(adapter_name) && config_adapters[adapter_name] != adapter_class
        raise "That adapter name has already been registered for #{config_adapters[adapter_name]}"
      else
        config_adapters[adapter_name] = adapter_class
      end
    end
  end

  private

  # Necessary to be able to check whether Rails is loaded and initialized
  def self.detect_rails
    require File.expand_path('../perpetuity/rails.rb', __FILE__) if defined? Rails
  end

  # Necessary until these adapters are updated to register themselves.
  def self.register_standard_adapters
    Perpetuity.register_adapter :mongodb => Perpetuity::MongoDB if defined?(Perpetuity::MongoDB)
    Perpetuity.register_adapter :postgres => Perpetuity::Postgres if defined?(Perpetuity::Postgres)
    Perpetuity.register_adapter :dynamodb => Perpetuity::DynamoDB if defined?(Perpetuity::DynamoDB)
  end
end
