module Perpetuity
  class Retrieval
    include Enumerable
    attr_accessor :sort_attribute, :sort_direction, :result_limit

    def initialize klass, criteria
      @class = klass
      @criteria = criteria
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
      results = Perpetuity.configuration.data_source.retrieve(@class, @criteria, { attribute: sort_attribute, direction: sort_direction, limit: result_limit })
      results.each do |result|
        result.instance_eval do
          def id
            @_id
          end
        end
      end
      
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
