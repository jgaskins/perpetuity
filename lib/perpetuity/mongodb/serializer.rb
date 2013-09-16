require 'perpetuity/data_injectable'
require 'perpetuity/reference'

module Perpetuity
  class MongoDB
    class Serializer
      include DataInjectable

      attr_reader :mapper, :mapper_registry

      def initialize(mapper)
        @mapper = mapper
        @class = mapper.mapped_class
        @mapper_registry = mapper.mapper_registry
      end

      def attribute_for object, attribute_name
        object.instance_variable_get("@#{attribute_name}")
      end

      def has_attribute? object, attribute_name
        object.instance_variable_defined? "@#{attribute_name}"
      end

      def serialize object
        attrs = mapper.attribute_set.map do |attrib|
          next unless has_attribute? object, attrib.name

          value = attribute_for object, attrib.name

          serialized_value = if value.is_a? Reference
            serialize_reference value
          elsif value.is_a? Array
            serialize_array(value, attrib.embedded?)
          elsif mapper.data_source.can_serialize? value
            value
          elsif mapper_registry.has_mapper?(value.class)
            serialize_with_foreign_mapper(value, attrib.embedded?)
          else
            marshal(value)
          end

          [attrib.name.to_s, serialized_value]
        end

        Hash[attrs.compact]
      end

      def serialize_changes changed, original
        Hash[Array(serialize(changed)) - Array(serialize(original))]
      end

      def unserialize data
        if data.is_a? Array
          unserialize_object_array data
        else
          object = unserialize_object(data)
          give_id_to object
          object
        end
      end

      def unserialize_object data, klass=@class
        if data.is_a? Hash
          object = klass.allocate
          data.each do |attr, value|
            inject_attribute object, attr, unserialize_attribute(value)
          end
          object
        else
          unserialize_attribute data
        end
      end

      def unserialize_object_array objects
        objects.map do |data|
          object = unserialize_object data
          give_id_to object
          object
        end
      end

      def unserialize_attribute data
        return data.map { |i| unserialize_attribute i } if data.is_a? Array
        return data unless data.is_a? Hash
        metadata  = data.fetch("__metadata__", {})
        marshaled = data.fetch("__marshaled__", false)

        if marshaled
          value = data.fetch("value")
          return unmarshal(value)
        end

        if metadata.any?
          klass = metadata['class'].split('::').inject(Kernel) do |scope, const_name|
            scope.const_get(const_name)
          end
          id = metadata['id']

          if id
            Reference.new(klass, id)
          else
            unserialize_object(data, klass)
          end
        else
          data
        end
      end

      def serialize_with_foreign_mapper value, embedded = false
        if embedded
          value_mapper = mapper_registry[value.class]
          value_serializer = Serializer.new(value_mapper)
          attr = value_serializer.serialize(value)
          attr.merge '__metadata__' =>  { 'class' => value.class }
        else
          serialize_reference(value)
        end
      end

      def serialize_array enum, embedded
        enum.map do |value|
          if value.is_a? Reference
            serialize_reference value
          elsif value.is_a? Array
            serialize_array(value)
          elsif mapper.data_source.can_serialize? value
            value
          elsif mapper_registry.has_mapper?(value.class)
            if embedded
              {
                '__metadata__' => {
                  'class' => value.class.to_s
                }
              }.merge mapper_registry[value.class].serialize(value)
            else
              serialize_reference value
            end
          else
            marshal value
          end
        end
      end

      def serialize_reference value
        if value.is_a? Reference
          reference = value
        else
          unless mapper.persisted? value
            mapper_registry[value.class].insert value
          end
          reference = Reference.new(value.class.to_s, mapper.id_for(value))
        end
        {
          '__metadata__' => {
            'class' => reference.klass.to_s,
            'id'    => reference.id
          }
        }
      end

      def marshal value
        {
          '__marshaled__' => true,
          'value' => Marshal.dump(value)
        }
      end

      def unmarshal value
        Marshal.load(value)
      end
    end
  end
end
