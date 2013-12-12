module Perpetuity
  class Duplicator
    attr_reader :object
    def initialize object
      if object.is_a? Array
        @object = object.map { |i| Duplicator.new(i).object }
      else
        @object = object.dup rescue object
      end
      @object.instance_variables.each do |ivar|
        duplicate_attribute ivar
      end
    end

    def attribute ivar
      object.instance_variable_get ivar
    end

    def set_attribute ivar, value
      object.instance_variable_set ivar, value
    end

    def duplicate_attribute ivar
      set_attribute ivar, Duplicator.new(attribute(ivar)).object
    end
  end
end
