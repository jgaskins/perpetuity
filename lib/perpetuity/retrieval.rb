module Perpetuity
  class Retrieval
    include Enumerable
    attr_accessor :sort_attribute, :sort_direction, :result_limit

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

    def each &block
      to_a.each &block
    end

    def to_a
      results = @data_source.retrieve(@class, @criteria, { attribute: sort_attribute, direction: sort_direction, limit: result_limit })
      
      results
    end

    def [] index
      to_a[index]
    end
    
    def limit lim
      retrieval = clone
      retrieval.result_limit = lim
      
      retrieval
    end
  end
end
