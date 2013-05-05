class User
  attr_accessor :name
  def initialize name="Foo"
    @name = name
  end

  def == other
    name == other.name
  end
end
