require 'perpetuity/data_injectable'
require 'perpetuity/reference'

module Perpetuity
  class Retrieval
    include DataInjectable
    include Enumerable
    attr_accessor :sort_attribute, :sort_direction, :result_limit, :result_page, :quantity_per_page

    def initialize klass, criteria, data_source = Perpetuity.configuration.data_source
      @class = klass
      @criteria = criteria
      @data_source = data_source
    end
    
    def sort attribute=:name
      retrieval = clone
      retrieval.sort_attribute = attribute
      retrieval.sort_direction = :ascending

      retrieval
    end

    def reverse
      retrieval = clone
      retrieval.sort_direction = retrieval.sort_direction == :descending ? :ascending : :descending

      retrieval
    end

    def page page
      retrieval = clone
      retrieval.result_page = page
      retrieval.quantity_per_page = 20
      retrieval
    end

    def per_page per
      retrieval = clone
      retrieval.quantity_per_page = per
      retrieval
    end

    def each &block
      to_a.each(&block)
    end

    def to_a
      options = {
        attribute: sort_attribute,
        direction: sort_direction,
        limit: result_limit || quantity_per_page,
        page: result_page
      }
      results = @data_source.retrieve(@class, @criteria, options)
      unserialize results
    end

    def unserialize(data)
      if data.is_a?(String) && data.start_with?("\u0004") # if it's marshaled
        Marshal.load(data)
      elsif data.is_a? Array
        data.map { |i| unserialize i }
      elsif data.is_a? Hash
        metadata = data.delete('__metadata__')
        if metadata
          klass = Object.const_get metadata['class']
          id = metadata['id']
          if id
            object = Reference.new(klass, id)
          else
            object = klass.allocate
            data.each do |attr, value|
              inject_attribute object, attr, unserialize(value)
            end
          end
        else
          object = @class.allocate
          data.each do |attr, value|
            inject_attribute object, attr, unserialize(value)
          end
        end

        give_id_to object
        object
      else
        data
      end
    end

    def [] index
      to_a[index]
    end

    def empty?
      to_a.empty?
    end
    
    def limit lim
      retrieval = clone
      retrieval.result_limit = lim
      
      retrieval
    end
  end
end
