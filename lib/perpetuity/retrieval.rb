class Perpetuity
  class Retrieval
    def initialize klass, criteria
      @class = klass
      @criteria = criteria
    end
    
    def [] index
      Perpetuity.data_source.retrieve(@class, @criteria)[index]
    end
  end
end