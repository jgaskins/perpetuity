module Perpetuity
  class Postgres
    class Serializer
      attr_reader :mapper

      def initialize mapper
        @mapper = mapper
      end

      def serialize object
        attrs = {}
        mapper.attribute_set.each do |attribute|
          attr_name = attribute.name.to_s
          attrs[attr_name] = object.instance_variable_get("@#{attr_name}")
        end

        attrs
      end
    end
  end
end
