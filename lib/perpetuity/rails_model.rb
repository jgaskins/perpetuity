module Perpetuity
  module RailsModel
    def self.included klass
      klass.extend ActiveModelish
    end

    def persisted?
      defined? @id
    end

    def to_param
      @id if persisted?
    end

    def to_key
      [to_param] if persisted?
    end

    module ActiveModelish
      def model_name
        self
      end

      def param_key
        self.to_s.downcase.gsub('::', '_')
      end

      def route_key
        if defined? ActiveSupport::Inflector
          ActiveSupport::Inflector.pluralize(param_key)
        else
          param_key + 's'
        end
      end

      def singular_route_key
        param_key
      end
    end
  end
end
