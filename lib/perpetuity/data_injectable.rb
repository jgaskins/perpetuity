require 'perpetuity/persisted_object'

module Perpetuity
  module DataInjectable
    def inject_attribute object, attribute, value
      object.instance_variable_set("@#{attribute}", value)
    end

    def inject_data object, data
      data.each_pair do |attribute,value|
        inject_attribute object, attribute, value
      end
      give_id_to object if object.instance_variables.include?(:@id)
    end

    def give_id_to object, *args
      if args.any?
        inject_attribute object, :id, args.first
      end
      object.extend PersistedObject
    end
  end
end
