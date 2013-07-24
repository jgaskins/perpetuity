module Perpetuity
  class NilQuery
    def self.new
      @instance ||= allocate
    end

    def to_db
      {}
    end
  end
end
