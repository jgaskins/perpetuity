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

    def model_name
      self.class.model_name
    end

    module ActiveModelish
      def model_name
        self
      end

      def param_key
        to_s.gsub('::', '_')
            .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
            .gsub(/([a-z\d])([A-Z])/,'\1_\2')
            .downcase
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

      def to_partial_path
        "#{name.downcase}s/_#{name.downcase}"
      end

      def human
        if name == name.upcase
          name.split(/_/).map(&:capitalize).join(' ')
        else
          name.gsub(/::|_/, ' ')
              .gsub(/(\w)([A-Z])/, '\1 \2')
        end
      end
    end
  end
end
