require 'perpetuity/validations/length'
require 'perpetuity/validations/presence'
require 'set'

module Perpetuity
  class ValidationSet < Set

    def valid? object
      each do |validation|
        return false unless validation.pass?(object)
      end

      true
    end

    def invalid? object
      !valid? object
    end

    def present attribute
      self << Perpetuity::Validations::Presence.new(attribute)
    end

    def length attribute, options = {}
      self << Perpetuity::Validations::Length.new(attribute, options)
    end
  end
end
