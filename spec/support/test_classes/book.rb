class Book
  attr_accessor :title, :authors
  def initialize title="Foo Bar #{Time.now.to_f.to_s}", authors=[]
    @title = title
    @authors = authors
  end
end
