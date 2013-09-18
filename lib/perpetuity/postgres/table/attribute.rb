module Perpetuity
  class Postgres
    class Table
      class Attribute
        attr_reader :name, :type, :max_length

        def initialize name, type, options={}
          @name = name
          @type = type
          @max_length = options[:max_length]
        end

        def sql_type
          if type == String
            if max_length
              "VARCHAR(#{max_length})"
            else
              'TEXT'
            end
          else
            'JSON'
          end
        end
      end
    end
  end
end
