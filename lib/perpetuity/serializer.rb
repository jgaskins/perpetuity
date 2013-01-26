module Perpetuity
  class Serializer
    attr_reader :mapper, :mapper_registry

    def initialize(mapper, mapper_registry)
      @mapper = mapper
      @mapper_registry = mapper_registry
    end

    def attribute_for object, attribute_name
      object.instance_variable_get("@#{attribute_name}")
    end

    def serialize object
      attrs = mapper.class.attribute_set.map do |attrib|
        value = attribute_for object, attrib.name

        serialized_value = if value.is_a? Array
          serialize_array(value, attrib.embedded?)
        elsif mapper.data_source.can_serialize? value
          value
        elsif mapper_registry.has_mapper?(value.class)
          serialize_with_foreign_mapper(value, attrib.embedded?)
        else
          if attrib.embedded?
            Marshal.dump(value)
          end
        end

        [attrib.name.to_s, serialized_value]
      end

      Hash[attrs]
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
        if value.is_a? Array
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
          Marshal.dump(value)
        end
      end
    end

    def serialize_reference value
      unless value.respond_to? :id
        mapper_registry[value.class].insert value
      end
      {
        '__metadata__' =>  {
          'class' => value.class.to_s,
          'id' => value.id
        }
      }
    end
  end
end
