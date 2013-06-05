class Car
  attr_accessor :make, :model, :seats

  def initialize attributes={}
    attributes.each do |attr, value|
      public_send "#{attr}=", value
    end
  end
end
