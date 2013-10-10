module Perpetuity
  class Postgres
    class Table
      class Attribute
        attr_reader :name, :type, :max_length

        NoDefaultValue = Module.new
        UUID = Module.new

        def initialize name, type, options={}
          @name = name
          @type = type
          @max_length = options[:max_length]
          @primary_key = options.fetch(:primary_key) { false }
          @default = options.fetch(:default) { NoDefaultValue }
        end

        def sql_type
          if type == String
            if max_length
              "VARCHAR(#{max_length})"
            else
              'TEXT'
            end
          elsif type == UUID
            'UUID'
          elsif type == Time
            'DATETIME'
          else
            'JSON'
          end
        end

        def sql_declaration
          if self.default.is_a? String
            default = "'#{self.default}'"
          else
            default = self.default
          end

          sql = "#{name} #{sql_type}"
          sql << ' PRIMARY KEY' if primary_key?
          sql << " DEFAULT #{default}" unless self.default == NoDefaultValue

          sql
        end

        def primary_key?
          !!@primary_key
        end

        def default
          @default
        end
      end
    end
  end
end
