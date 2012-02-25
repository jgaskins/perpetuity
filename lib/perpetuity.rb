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
      @serializable_types ||= [NilClass, TrueClass, FalseClass, Fixnum, Bignum, Float, String, Array, Hash]
    end

    def self.insert object
      raise "#{object} is invalid and cannot be persisted." if object.respond_to?(:valid?) and !object.valid?
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
      objects = data_source.all mapped_class
      objects.each do |object|
        object.define_singleton_method(:id) { @_id }
      end
    end

    def self.retrieve criteria={}
      Perpetuity::Retrieval.new mapped_class, criteria
    end

    def self.find id
      retrieve(id: id).first
    end

    def self.delete object
      data_source.delete object
    end

    def self.load_association! object, attribute
      class_name = object.send(attribute)["class_name"]
      id = object.send(attribute)["id"]

      mapper = Module.const_get("#{class_name}Mapper")
      associated_object = mapper.find(id)
      object.send("#{attribute}=", associated_object)
    end
  end
end
