class Book
  attr_accessor :title, :authors
  def initialize title="Foo Bar", authors=[]
    @title = title
    @authors = authors
  end
end
