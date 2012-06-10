module Perpetuity
  class Configuration
    def data_source *args
      if args.any?
        @db = args.pop
      end

      @db
    end
  end
end
