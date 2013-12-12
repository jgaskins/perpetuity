require 'perpetuity/duplicator'
require 'support/test_classes/book'
require 'support/test_classes/user'

module Perpetuity
  describe Duplicator do
    let(:authors) { [User.new('Dave'), User.new('Andy')] }
    let(:book) { Book.new('Title', authors) }
    let(:duper) { Duplicator.new(book) }

    it 'duplicates an object' do
      duper.object.should be_a Book
      duper.object.should_not be book
    end

    it 'duplicates attributes inside an object' do
      duped_book = duper.object
      duped_book.title.should be_a String
      duped_book.title.should == book.title
      duped_book.title.should_not be book.title
    end

    it 'does not duplicate non-duplicable attributes' do
      # Symbols cannot be duped
      book = Book.new(:foo)
      duper = Duplicator.new(book)
      duper.object.title.should be :foo
    end

    it 'duplicates objects contained within array attributes' do
      duper.object.authors.first.should be_a User
      duper.object.authors.first.should_not be authors.first
    end
  end
end
