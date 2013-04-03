module Perpetuity
  module PersistedObject
    def id
      @id if defined? @id
    end
  end
end
