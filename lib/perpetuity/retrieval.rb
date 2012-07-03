require 'perpetuity/data_injectable'

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
      objects = []
      results.each do |result|
        object = @class.allocate
        inject_data object, Mapper.unserialize(result)

        objects << object
      end

      objects
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
