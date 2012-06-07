require 'perpetuity/attribute_set'
require 'perpetuity/attribute'
require 'perpetuity/validations'

module Perpetuity
  class Mapper
    attr_accessor :object, :original_object

    def initialize(object = nil)
      @object = object
      @original_object = object.dup
    end

    def self.attribute_set
      @attribute_set ||= AttributeSet.new
    end

    def self.attribute name, type
      attribute_set << Attribute.new(name, type)
    end

    def self.attributes
      attribute_set.map(&:name)
    end

    def self.delete_all
      data_source.delete_all mapped_class
    end

    def self.serializable_types
      @serializable_types ||= [NilClass, TrueClass, FalseClass, Fixnum, Bignum, Float, String, Array, Hash, Time, Date]
    end

    def serializable_types
      self.class.serializable_types
    end

    def validations
      self.class.validations
    end

    def attributes_for object
      self.class.attributes_for object
    end

    def data_source
      self.class.data_source
    end

    def give_id_to object, new_id
      self.class.give_id_to object, new_id
    end

    def mapped_class
      self.class.mapped_class
    end

    def self.insert object
      new(object).insert
    end

    def insert
      raise "#{object} is invalid and cannot be persisted." unless validations.valid?(object)
      serializable_attributes = {}
      serializable_attributes[:id] = object.instance_eval(&self.class.id) unless self.class.id.nil?

      attributes_for(object).each_pair do |attribute, value|
        if serializable_types.include? value.class
          serializable_attributes[attribute] = value
        elsif value.respond_to?(:id)
          serializable_attributes[attribute] = value.id
        else
          raise "Must persist #{attribute} (#{value.inspect}) before persisting this #{object.inspect}."
        end
      end

      new_id = data_source.insert mapped_class, serializable_attributes
      give_id_to object, new_id
      new_id
    end

    def self.give_id_to object, given_id
      object.define_singleton_method :id, -> { given_id }
    end

    def self.attributes_for object
      attrs = {}
      attribute_set.each do |attrib|
        attrs[attrib.name] = object.send(attrib.name)
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
      data_source.first mapped_class
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
      data_source.delete object, mapped_class
    end

    def self.load_association! object, attribute
      class_name = attribute_set[attribute].type
      id = object.send(attribute)

      mapper = Module.const_get("#{class_name}Mapper")
      associated_object = mapper.find(id)
      object.send("#{attribute}=", associated_object)
    end

    def self.id &block
      if block_given?
        @id = block
      else
        @id
      end
    end

    def self.update object, new_data
      id = object.is_a?(mapped_class) ? object.id : object

      data_source.update mapped_class, id, new_data
    end

    def self.validate &block
      @validations ||= ValidationSet.new

      validations.instance_exec &block
    end

    def self.validations
      @validations ||= ValidationSet.new
    end

    def changed_attributes
      changes = {}

      self.class.attributes.each do |attribute|
        unless object.send(attribute) == original_object.send(attribute)
          changes[attribute] = object.send(attribute)
        end
      end

      changes
    end

    def save
      self.class.update object, changed_attributes
    end
  end
end

