require "perpetuity/version"
require "perpetuity/retrieval"
require "perpetuity/mongodb"
require "perpetuity/config"

module Perpetuity
  def self.configure &block
    configuration.instance_exec &block  
  end
  
  def self.configuration
    @@configuration ||= Configuration.new
  end

  class Mapper
    def self.attribute name, type
      @attributes ||= []
      @attributes << name.to_sym
    end
    
    def self.attributes
      @attributes
    end

    def self.delete_all
      data_source.delete_all mapped_class
    end

    def self.serializable_types
      @serializable_types ||= [TrueClass, FalseClass, Fixnum, Bignum, Float, String, Array, Hash]
    end

    def self.insert object
      serializable_attributes = {}
      attributes_for(object).each_pair do |attribute, value|
        if serializable_types.include? value.class
          serializable_attributes[attribute] = value
        elsif value.respond_to?(:id)
          serializable_attributes[attribute] = { class_name: value.class.to_s, id: value.id }
        else
          raise "Must persist #{attribute} (#{value.inspect}) before persisting this #{object.inspect}."
        end
      end

      new_id = data_source.insert mapped_class, serializable_attributes
      give_id_to object, new_id
    end

    def self.give_id_to object, given_id
      object.define_singleton_method :id, -> { given_id }
    end
    
    def self.attributes_for object
      attrs = {}
      attributes.each do |attrib|
        attrs[attrib] = object.send(attrib)
      end
      attrs
    end
    
    def self.data_source
      Perpetuity.configuration.data_source
    end

    def self.count
      data_source.count mapped_class
    end
    
    def self.mapped_class
      Module.const_get self.name.gsub('Mapper', '').to_sym
    end

    def self.first
      retrieve.limit(1).first
    end

    def self.all
      data_source.all mapped_class
    end

    def self.retrieve criteria={}
      Perpetuity::Retrieval.new mapped_class, criteria
    end

    def self.delete object
      data_source.delete object
    end

  end
  
  
  # def insert
  #   # @object.instance_variables.each do |ivar|
  #   #   ivalue = @object.instance_variable_get ivar
  #   #   
  #   #   # If it's not a serializable value, we need to save this value separately.
  #   #   unless [String, Fixnum, Bignum, Hash, Array, TrueClass, FalseClass, NilClass].include? ivalue.class
  #   #     unless ivalue.instance_variable_defined?(Perpetuity.data_source.id_attribute)
  #   #     end
  #   #   end
  #   # end
  # 
  #   Perpetuity.data_source.insert @object
  # end
  # 
  # 
  # def self.count klass
  #   Perpetuity.data_source.count klass
  # end
  # 
  # def self.all klass
  #   Perpetuity.data_source.all klass
  # end
  # 
  # 
  # def object_attributes
  #   attributes = {}
  #   @object.instance_variables.each do |ivar|
  #     ivar_symbol = ivar.to_s.sub('@', '').to_sym
  #     attributes[ivar_symbol] = @object.instance_variable_get(ivar)
  #   end
  #   
  #   attributes
  # end
end
