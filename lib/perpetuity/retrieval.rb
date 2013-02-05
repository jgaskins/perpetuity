require 'perpetuity/reference'
require 'perpetuity/serializer'

module Perpetuity
  class Retrieval
    include Enumerable
    attr_accessor :sort_attribute, :sort_direction, :result_limit, :result_page, :quantity_per_page

    def initialize mapper, criteria
      @mapper = mapper
      @class = mapper.mapped_class
      @criteria = criteria
      @data_source = mapper.data_source
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
      Serializer.new(@mapper).unserialize(data)
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
