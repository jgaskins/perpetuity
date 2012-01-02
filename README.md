# Perpetuity

Perpetuity is a simple Ruby object persistence layer that attempts to follow Martin Fowler's Data Mapper pattern, allowing you to use plain-old Ruby objects (POROs) in your Rails apps in order to decouple your domain logic from the database as well as speed up your tests without creating piles of extra classes/modules with minimal functionality.

Your objects will hopefully eventually be able to be persisted into whichever backend you like. Right now, only MongoDB is supported. Other schemaless persistence solutions should be relatively simple to implement. I haven't tried it yet, but I imagine anything that requires a schema might be more difficult.

The idea is that your objects don't have a clue what a database is. They don't include any persistence logic inside them whatsoever. This idea was inspired by [a blog post by Steve Klabnik](http://blog.steveklabnik.com/posts/2011-12-30-active-record-considered-harmful) and [Avdi Grimm's Objects on Rails](http://avdi.org/devblog/2011/11/15/early-access-beta-of-objects-on-rails-now-available-2/).

## Installation

Add the following to your Gemfile and run `bundle` to install it.

```ruby
gem 'perpetuity', git: 'git://github.com/jgaskins/perpetuity.git'
```

## Configuration

The only currently supported persistence method is MongoDB. Other schemaless solutions can probably be implemented easily.

```ruby
Perpetuity.config.data_source = Perpetuity::MongoDB.new host: 'mongodb.example.com', db: 'example_db'
```

## Saving Objects

```ruby
class Article
  attr_accessor :title, :body
end

article = Article.new
article.title = 'New Article'
article.body = 'This is an article.'

article_mapper = Perpetuity.new article
article_mapper.insert
```

## Loading Objects

You can load all persisted objects by calling `Perpetuity.all` and passing in the class of the object.

```ruby
Perpetuity.all Article
```

You can load specific objects by calling `Perpetuity.retrieve` and passing in the class and criteria.

```ruby
article = Perpetuity.retrieve Article, id: params[:id]
user = Perpetuity.retrieve User, email: 'user@example.com'
```

So far, the query interface is too simple. What I'd like to have it able to do would be something like the following:

```ruby
users = Perpetuity.retrieve User, post_count: { greater_than: 100, less_than: 1000 }
articles = Perpetuity.retrieve Article, tags: { includes: ['ruby', 'rails'] }
comments = Perpetuity.retrieve Comment, article_id: { in: articles.map(&:id) }
```

This will return a Perpetuity::Retrieval object, which will lazily retrieve the objects from the database. They will wait to hit the DB when you begin iterating over the objects so you can continue chaining methods.

```ruby
articles = Perpetuity.retrieve(Article, published: false).or(views: { less_than: 10 })
articles = articles.sort(:date_published).reverse.limit(10)

articles.each do |article| # This is when the DB gets hit
  # Display the pretty articles
end
```

Counting `:gt` and `:lt` as aliases for `:greater_than` and `:less_than`, respectively, might be nice.

## Objects That Associate with Other Objects

If an object has an attribute that isn't an array, hash, boolean, string or numeric value, that attribute will be persisted as a separate object. In the following code …

```ruby
class User
  attr_accessor :articles
  
  def initialize name
    @name = name
  end
  
  def publish_article title, body
    Article.new title, self, body
  end
end

class Article
  attr_accessor :author
  
  def initialize title, author, body
    @title = title
    @author = author
    @body = body
  end
end
```

```ruby
author = User.new 'Jamie'
article = Article.new 'Don\'t Panic', author, 'Forty-two.'
article_mapper = Perpetuity.new article
article_mapper.insert
```

… the User object that represents the author will also be persisted if it isn't already.

## Specifying Persistence Logic

I know what you're thinking: "This is all well and good, Jamie, but I need to be able to specify some of the persistence logic necessary for my class."

It's true, sometimes you do need to do this. For example, your blog articles should be stored using their parameterized names as keys for SEO purposes. Your users can't have duplicate e-mail addresses. You can't show the same cat picture twice in two consecutive posts.

In order to place restrictions or customisations on your persisted data, write a mapper class that inherits from the `Perpetuity::Mapper` class.
```ruby
class ArticleMapper < Perpetuity::Mapper
  id ->(article) { article.name.parameterize }
end

class UserMapper < Perpetuity::Mapper
  unique :email
end
```

*Note: These classes aren't the ones containing the data you're persisting. They're those classes' interfaces to the database.*

## Contributing

Right now, this code is pretty bare and there's a bit of duplication in the tests … and possibly some stupid design decisions. You can help. If you have ideas to build on this, send some love in the form of pull requests or issues or tweets or e-mails and I'll do what I can for them.