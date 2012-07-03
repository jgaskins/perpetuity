require 'perpetuity/attribute_set'
require 'perpetuity/attribute'
require 'perpetuity/validations'
require 'perpetuity/data_injectable'
require 'perpetuity/mongodb/query'

module Perpetuity
  class Mapper
    extend DataInjectable
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

    def validations
      self.class.validations
    end

    def attributes_for object
      self.class.attributes_for object
    end

    def data_source
      self.class.data_source
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
      if o_id = object.instance_exec(&self.class.id)
        serializable_attributes[:id] = o_id
      end

      attributes_for(object).each_pair do |attribute, value|
        if self.class.serializable_types.include? value.class
          serializable_attributes[attribute] = value
        elsif value.respond_to?(:id)
          serializable_attributes[attribute] = value.id
        else
          raise "Must persist #{attribute} (#{value.inspect}) before persisting this #{object.inspect}."
        end
      end

      new_id = data_source.insert mapped_class, serializable_attributes
      give_id new_id
      new_id
    end

    def give_id new_id
      self.class.give_id_to object, new_id
    end

    def self.attributes_for object
      attrs = {}
      attribute_set.each do |attrib|
        value = object.send(attrib.name)

        if attrib.type == Array
          new_array = []
          value.each do |i|
            if serializable_types.include? i.class
              new_array << i
            else
              new_array << {
                :type => :object,
                :class => i.class.to_s,
                attributes: mapper_for(i.class).attributes_for(i)
              }
            end
          end

          attrs[attrib.name] = new_array
        else
          attrs[attrib.name] = value
        end
      end
      attrs
    end

    def self.unserialize(data)
      if data.is_a?(Hash) && data.keys.map(&:to_s) == %w( type class attributes )
        klass = Module.const_get(data[:class] || data["class"])
        object = klass.allocate
        inject_data object, (data[:attributes] || data["attributes"])

        object
      elsif data.is_a? Array
        data.map { |i| unserialize i }
      elsif data.is_a? Hash
        Hash[data.map{|k,v| [k, unserialize(v)]}]
      else
        data
      end
    end

    def self.mapper_for klass
      Module.const_get "#{klass}Mapper"
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
      data = data_source.first mapped_class
      object = mapped_class.allocate
      inject_data object, data

      object
    end

    def self.all
      results = data_source.all mapped_class
      objects = []
      results.each do |result|
        object = mapped_class.allocate
        inject_data object, result

        objects << object
      end

      objects
    end

    def self.retrieve criteria={}
      Perpetuity::Retrieval.new mapped_class, criteria
    end

    def self.select &block
      query = data_source.class::Query.new(&block).to_db
      retrieve query
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
        @id ||= -> { nil }
      end
    end

    def self.update object, new_data
      id = object.is_a?(mapped_class) ? object.id : object

      data_source.update mapped_class, id, new_data
    end

    def self.validate &block
      @validations ||= ValidationSet.new

      validations.instance_exec(&block)
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

