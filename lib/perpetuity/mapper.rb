require 'perpetuity/attribute_set'
require 'perpetuity/attribute'
require 'perpetuity/validations'
require 'perpetuity/data_injectable'
require 'perpetuity/mongodb/query'

module Perpetuity
  class Mapper
    include DataInjectable

    def self.generate_for(klass, &block)
      mapper = Class.new(base_class, &block)
      mapper.map klass
    end

    def self.mappers
      @mappers ||= {}
    end

    def self.map klass
      add_mapper klass, self
      @mapped_class = klass
    end

    def self.add_mapper klass, mapper
      base_class.mappers[klass] = self
    end

    def self.attribute_set
      @attribute_set ||= AttributeSet.new
    end

    def self.attribute name, type, options = {}
      attribute_set << Attribute.new(name, type, options)
    end

    def self.attributes
      attribute_set.map(&:name)
    end

    def attributes
      self.class.attributes
    end

    def delete_all
      data_source.delete_all mapped_class
    end

    def insert object
      raise "#{object} is invalid and cannot be persisted." unless self.class.validations.valid?(object)
      serializable_attributes = serialize(object)
      if o_id = object.instance_exec(&self.class.id)
        serializable_attributes[:id] = o_id
      end

      new_id = data_source.insert mapped_class, serializable_attributes
      give_id_to object, new_id
      new_id
    end

    def serialize object
      attrs = {}
      self.class.attribute_set.each do |attrib|
        value = object.send(attrib.name)
        attrib_name = attrib.name.to_s

        if value.respond_to? :each
          attrs[attrib_name] = serialize_enumerable(value)
        elsif data_source.can_serialize? value
          attrs[attrib_name] = value
        elsif Mapper[value.class]
          if attrib.embedded?
            attrs[attrib_name] = Mapper[value.class].serialize(value).merge '__metadata__' =>  { 'class' => value.class }
          else
            attrs[attrib_name] = {
              '__metadata__' =>  {
                'class' => value.class.to_s,
                'id' => value.id
              }
            }
          end
        else
          if attrib.embedded?
            attrs[attrib_name] = Marshal.dump(value)
          end
        end
      end

      attrs
    end

    def serialize_enumerable enum
      enum.map do |value|
        if value.respond_to? :each
          serialize_enumerable(value)
        elsif data_source.can_serialize? value
          value
        elsif Mapper.has_mapper?(value.class)
          {
            '__metadata__' => {
              'class' => value.class.to_s
            }
          }.merge Mapper[value.class].serialize(value)
        else
          Marshal.dump(value)
        end
      end
    end

    def self.has_mapper? klass
      mappers.has_key? klass
    end

    def self.[] klass
      mappers[klass].new
    end

    def data_source
      Perpetuity.configuration.data_source
    end

    def count
      data_source.count mapped_class
    end

    def self.mapped_class
      @mapped_class
    end

    def mapped_class
      self.class.mapped_class
    end

    def first
      data = data_source.first mapped_class
      object = mapped_class.new
      inject_data object, data

      object
    end

    def all
      results = data_source.all mapped_class
      objects = []
      results.each do |result|
        object = mapped_class.new
        inject_data object, result

        objects << object
      end

      objects
    end

    def retrieve criteria={}
      Perpetuity::Retrieval.new mapped_class, criteria
    end

    def select &block
      query = data_source.class::Query.new(&block).to_db
      retrieve query
    end

    def find id
      retrieve(id: id).first
    end

    def delete object
      data_source.delete object, mapped_class
    end

    def load_association! object, attribute
      reference = object.send(attribute)
      klass = reference.klass
      id = reference.id

      inject_attribute object, attribute, Mapper[klass].find(id)
    end

    def self.id &block
      if block_given?
        @id = block
      else
        @id ||= -> { nil }
      end
    end

    def update object, new_data
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

    private
    def self.base_class
      Mapper
    end
  end
end

