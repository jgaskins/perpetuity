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

      def serialize_attribute value
        if value.is_a? String
          "'#{value}'"
        elsif value.is_a? Numeric
          value
        elsif value.nil?
          'NULL'
        elsif value == true || value == false
          value.to_s.upcase
        else
          value.to_json
        end
      end
    end
  end
end
