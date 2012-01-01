require "mapper/version"
require "mapper/mongodb"
require "mapper/config"

class Mapper
  def initialize object
    @object = object
  end

  def self.config
    @@config ||= Config.new
  end
  
  def self.data_source
    config.data_source
  end
  
  def insert
    Mapper.data_source.insert @object
  end
  
  def self.retrieve klass, criteria
    Mapper.data_source.retrieve klass, criteria
  end
  
  def self.count klass
    Mapper.data_source.count klass
  end
  
  def self.all klass
    Mapper.data_source.all klass
  end
  
  def self.delete klass
    Mapper.data_source.delete klass
  end
  
  def object_attributes
    attributes = {}
    @object.instance_variables.each do |ivar|
      attributes[ivar] = @object.instance_variable_get(ivar)
    end
    
    attributes
  end
end