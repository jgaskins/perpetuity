require 'perpetuity/postgres/query'

module Perpetuity
  class Postgres
    def query klass, &block
      Query.new(klass, &block)
    end
  end
end
