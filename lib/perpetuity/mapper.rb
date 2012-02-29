require 'attribute_set'
require 'attribute'

module Perpetuity
  class Mapper
    def self.attribute name, type
      @attributes ||= AttributeSet.new
      @attributes << Attribute.new(name, type)
    end

    def self.attributes
      @attributes.map(&:name)
    end

    def self.delete_all
      data_source.delete_all mapped_class
    end

    def self.serializable_types
      @serializable_types ||= [NilClass, TrueClass, FalseClass, Fixnum, Bignum, Float, String, Array, Hash, Time, Date]
    end

    def self.insert object
      raise "#{object} is invalid and cannot be persisted." if object.respond_to?(:valid?) and !object.valid?
      serializable_attributes = {}
      serializable_attributes[:id] = object.instance_eval(&@id) unless @id.nil?

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
    end

    def self.give_id_to object, given_id
      object.define_singleton_method :id, -> { given_id }
    end

    def self.attributes_for object
      attrs = {}
      @attributes.each do |attrib|
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
      class_name = @attributes[attribute].type
      id = object.send(attribute)

      mapper = Module.const_get("#{class_name}Mapper")
      associated_object = mapper.find(id)
      object.send("#{attribute}=", associated_object)
    end

    def self.id &block
      @id = block
    end

    def self.update object, new_data
      id = object.is_a?(mapped_class) ? object.id : object

      data_source.update mapped_class, id, new_data
    end
  end
end

# Allow users to use calls like mapper.retrieve(:attribute < value)
class Symbol
  def > object
    Perpetuity.configuration.data_source.inequality self, :>, object
  end

  def < object
    Perpetuity.configuration.data_source.inequality self, :<, object
  end

  def >= object
    Perpetuity.configuration.data_source.inequality self, :>=, object
  end

  def <= object
    Perpetuity.configuration.data_source.inequality self, :<=, object
  end
end
