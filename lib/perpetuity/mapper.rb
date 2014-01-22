require 'perpetuity/attribute_set'
require 'perpetuity/attribute'
require 'perpetuity/data_injectable'
require 'perpetuity/dereferencer'
require 'perpetuity/retrieval'
require 'perpetuity/dirty_tracker'

module Perpetuity
  class Mapper
    include DataInjectable
    attr_reader :mapper_registry, :identity_map, :dirty_tracker

    def initialize registry=Perpetuity.mapper_registry, id_map=IdentityMap.new
      @mapper_registry = registry
      @identity_map = id_map
      @dirty_tracker = DirtyTracker.new
    end

    def self.map klass, registry=Perpetuity.mapper_registry
      registry[klass] = self
      @mapped_class = klass
    end

    def self.attribute_set
      @attribute_set ||= AttributeSet.new
    end

    def self.attribute name, options = {}
      type = options.fetch(:type) { nil }
      attribute_set << Attribute.new(name, type, options)
    end

    def self.attributes
      attribute_set.map(&:name)
    end

    def self.index attribute, options={}
      data_source.index mapped_class, attribute_set[attribute], options
    end

    def remove_index! index
      data_source.remove_index index
    end

    def indexes
      data_source.indexes(mapped_class)
    end

    def reindex!
      indexes.each { |index| data_source.activate_index! index }
      unspecified_indexes.each do |index|
        data_source.remove_index index
      end
    end

    def unspecified_indexes
      active_indexes = data_source.active_indexes(mapped_class)
      active_but_unspecified_indexes = (active_indexes - indexes)
      active_but_unspecified_indexes.reject { |index| index.attribute =~ /id/ }
    end

    def attributes
      self.class.attributes
    end

    def attribute_set
      self.class.attribute_set
    end

    def delete_all
      data_source.delete_all mapped_class
    end

    def insert object
      objects = Array(object)
      serialized_objects = objects.map { |obj| serialize(obj) }

      new_ids = data_source.insert(mapped_class, serialized_objects, attribute_set)
      objects.each_with_index do |obj, index|
        give_id_to obj, new_ids[index]
      end

      if object.is_a? Array
        new_ids
      else
        new_ids.first
      end
    end

    def generate_id_for object
      object.instance_exec(&self.class.id)
    end

    def self.data_source(configuration=Perpetuity.configuration)
      configuration.data_source
    end

    def count &block
      data_source.count mapped_class, &block
    end

    def any? &block
      count(&block) > 0
    end

    def all? &block
      count(&block) == count
    end

    def one? &block
      count(&block) == 1
    end

    def none? &block
      !any?(&block)
    end

    def first
      retrieve.limit(1).first
    end

    def all
      retrieve
    end

    def select &block
      retrieve data_source.query(&block)
    end

    alias :find_all :select

    def find id=nil, &block
      if block_given?
        select(&block).first
      else
        cached_value = identity_map[mapped_class, id]
        return cached_value if cached_value

        result = if id.is_a? Array
                   select { |object| object.id.in id }
                 else
                   select { |object| object.id == id }.first
                 end

        unless result.nil?
          identity_map << result
          dirty_tracker << result
        end

        result
      end
    end

    alias :detect :find

    def reject &block
      retrieve data_source.negate_query(&block)
    end

    def delete object
      id = persisted?(object) ? id_for(object) : object
      data_source.delete id, mapped_class
    end

    def load_association! object, attribute
      objects = Array(object)
      dereferencer = Dereferencer.new(mapper_registry, identity_map)
      dereferencer.load objects.map { |obj| obj.instance_variable_get("@#{attribute}") }

      objects.each do |obj|
        reference = obj.instance_variable_get("@#{attribute}")
        if reference.is_a? Array
          refs = reference
          real_objects = refs.map { |ref| dereferencer[ref] }
          inject_attribute obj, attribute, real_objects
        else
          inject_attribute obj, attribute, dereferencer[reference]
        end
      end
    end

    def self.id type=nil, &block
      if block_given?
        @id = block
        if type
          attribute :id, type: type
        end
        nil
      else
        @id ||= -> { nil }
      end
    end

    def update object, new_data, update_in_memory = true
      id = object.is_a?(mapped_class) ? id_for(object) : object

      inject_data object, new_data if update_in_memory
      data_source.update mapped_class, id, new_data
    end

    def save object
      changed_attributes = serialize_changed_attributes(object)
      if changed_attributes && changed_attributes.any?
        update object, changed_attributes
      else
        update object, serialize(object), false
      end
    end

    def increment object, attribute, count=1
      id = id_for(object) || object
      data_source.increment mapped_class, id, attribute, count
    end

    def decrement object, attribute, count=1
      id = id_for(object) || object
      data_source.increment mapped_class, id, attribute, -count
    end

    def sample
      all.sample
    end

    def persisted? object
      object.instance_variable_defined?(:@id)
    end

    def id_for object
      object.instance_variable_get(:@id) if persisted?(object)
    end

    def data_source
      self.class.data_source
    end

    def serialize object
      attributes = data_source.serialize(object, self)
      if o_id = generate_id_for(object)
        attributes['id'] = o_id
      end

      attributes
    end

    def serialize_changed_attributes object
      cached = dirty_tracker[object.class, id_for(object)]
      if cached
        data_source.serialize_changed_attributes(object, cached, self)
      end
    end

    def self.mapped_class
      @mapped_class
    end

    def mapped_class
      self.class.mapped_class
    end

    private

    def retrieve query=data_source.query
      Perpetuity::Retrieval.new self, query
    end
  end
end

