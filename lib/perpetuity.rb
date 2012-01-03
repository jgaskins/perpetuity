require "perpetuity/version"
require "perpetuity/retrieval"
require "perpetuity/mongodb"
require "perpetuity/config"

class Perpetuity
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
    Perpetuity.data_source.insert @object
  end
  
  def self.retrieve klass, criteria
    Perpetuity::Retrieval.new klass, criteria
  end
  
  def self.count klass
    Perpetuity.data_source.count klass
  end
  
  def self.all klass
    Perpetuity.data_source.all klass
  end
  
  def self.delete klass
    Perpetuity.data_source.delete klass
  end
  
  def object_attributes
    attributes = {}
    @object.instance_variables.each do |ivar|
      attributes[ivar.to_s.sub('@', '').to_sym] = @object.instance_variable_get(ivar)
    end
    
    attributes
  end
end