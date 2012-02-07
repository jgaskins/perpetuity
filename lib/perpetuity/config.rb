module Perpetuity
  class Configuration
    def data_source db=nil
      if db.nil?
        @@db
      else
        @@db = db
      end
    end
  end
end