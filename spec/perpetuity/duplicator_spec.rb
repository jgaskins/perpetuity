require 'perpetuity/duplicator'
require 'support/test_classes/book'
require 'support/test_classes/user'

module Perpetuity
  describe Duplicator do
    let(:authors) { [User.new('Dave'), User.new('Andy')] }
    let(:book) { Book.new('Title', authors) }
    let(:duper) { Duplicator.new(book) }

    it 'duplicates an object' do
      expect(duper.object).to be_a Book
      expect(duper.object).not_to be book
    end

    it 'duplicates attributes inside an object' do
      duped_book = duper.object
      expect(duped_book.title).to be_a String
      expect(duped_book.title).to be == book.title
      expect(duped_book.title).not_to be book.title
    end

    it 'does not duplicate non-duplicable attributes' do
      # Symbols cannot be duped
      book = Book.new(:foo)
      duper = Duplicator.new(book)
      expect(duper.object.title).to be :foo
    end

    it 'duplicates objects contained within array attributes' do
      expect(duper.object.authors.first).to be_a User
      expect(duper.object.authors.first).not_to be authors.first
    end
  end
end
