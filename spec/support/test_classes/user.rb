class User
  attr_accessor :name
  def initialize name="Foo"
    @name = name
  end

  def == other
    other.is_a?(self.class) && name == other.name
  end
end
