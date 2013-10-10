require 'json'
module Perpetuity
  class Postgres
    class Serializer
      attr_reader :mapper

      def initialize mapper
        @mapper = mapper
      end

      def serialize object
        attrs = mapper.attribute_set.map do |attribute|
          attr_name = attribute.name.to_s
          value = object.instance_variable_get("@#{attr_name}")
          serialize_attribute(value)
        end.join(',')

        "(#{attrs})"
      end

      def serialize_attribute value
        if value.is_a? String
          "'#{value}'"
        elsif value.is_a? Numeric
          value
        elsif value.is_a? Array
          serialize_array value
        elsif value.is_a? Time

        elsif value.nil?
          'NULL'
        elsif value == true || value == false
          value.to_s.upcase
        else
          value.to_json
        end
      end

      def serialize_array value
        %Q('#{value.map { |item| serialize_within_json(item) }}')
      end

      def serialize_within_json value
        if value.is_a? Numeric
          value
        elsif value.is_a? String
          value
        end
      end
    end
  end
end
