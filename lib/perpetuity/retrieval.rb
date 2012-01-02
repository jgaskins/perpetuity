class Perpetuity
  class Retrieval
    attr_accessor :sort_attribute, :sort_direction

    def initialize klass, criteria
      @class = klass
      @criteria = criteria
    end
    
    def sort attribute=:name
      retrieval = clone
      retrieval.sort_attribute = attribute.to_s.prepend('@').to_sym
      retrieval.sort_direction = :ascending

      retrieval
    end

    def reverse
      retrieval = clone
      retrieval.sort_direction = retrieval.sort_direction == :descending ? :ascending : :descending

      retrieval
    end

    def to_a
      Perpetuity.data_source.retrieve(@class, @criteria, { attribute: sort_attribute, direction: sort_direction })
    end

    def [] index
      to_a[index]
    end

    def map(&block)
      to_a.map(&block)
    end
  end
end