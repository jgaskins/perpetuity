require 'perpetuity/reference'

module Perpetuity
  class Retrieval
    include Enumerable
    attr_accessor :sort_attribute, :sort_direction, :result_limit, :result_page, :result_offset

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
      retrieval.result_limit ||= 20
      retrieval.result_page = page
      retrieval.result_offset = (page - 1) * retrieval.result_limit
      retrieval
    end

    def per_page per
      retrieval = clone
      retrieval.result_limit = per
      retrieval.result_offset = (retrieval.result_page - 1) * per
      retrieval
    end

    def each &block
      to_a.each(&block)
    end

    def to_a
      @results ||= @data_source.unserialize(@data_source.retrieve(@class, @criteria, options), @mapper)
    end

    def count
      @data_source.count(@class, @criteria)
    end

    def sample
      sample_size = [count, result_limit].compact.max
      result = drop(rand(sample_size)).first
      result
    end

    def options
      {
        attribute: sort_attribute,
        direction: sort_direction,
        limit: result_limit,
        skip: result_offset
      }
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

    def drop count
      retrieval = clone
      retrieval.result_offset = count

      retrieval
    end
  end
end
