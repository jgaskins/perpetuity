# Mapper

Mapper is a simple Ruby object persistence layer that attempts to follow Martin Fowler's Data Mapper pattern, allowing you to use plain-old Ruby objects (POROs) in your Rails apps in order to decouple your domain logic from the database as well as speed up your tests without creating piles of extra classes/modules with minimal functionality. Your objects will hopefully eventually be able to be persisted into whichever backend you like. Right now, only MongoDB is supported. Other schemaless persistence solutions should be relatively simple to implement. I haven't tried it yet, but I imagine anything that requires a schema might be more difficult.

## Installation

Add the following to your Gemfile and run `bundle` to install it.

```ruby
gem 'mapper', git: 'https://github.com/jgaskins/mapper.git'
```

## Configuration

The only currently supported persistence method is MongoDB. Other solutions can probably be implemented easily.

```ruby
Mapper.config.data_source = Mapper::MongoDB.new host: 'mongodb.example.com', db: 'example_db'
```

## Saving Objects

```ruby
class Article
  attr_accessor :title, :body
end

article = Article.new
article.title = 'New Article'
article.body = 'This is an article.'

article_mapper = Mapper.new article
article_mapper.insert
```

## Loading Objects

Loading articles is as easy as a single call to `Mapper.load`. Required parameters are the class of the object and a hash of criteria for finding the object.

```ruby
article = Mapper.retrieve Article, id: 1
user = Mapper.retrieve User, email: 'user@example.com'
```

So far, the query interface is too simple. What I'd like to have it able to do would be something like the following:

```ruby
user = Mapper.retrieve User, post_count: { greater_than: 100, less_than: 1000 }
article = Mapper.retrieve
```

Counting `:greater_than` and `:less_than` as aliases for `:gt` and `:lt`, respectively, might be nice.

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
article_mapper = Mapper.new article
article_mapper.insert
```

… the User object that represents the author will also be persisted if it isn't already.

**NOTE:** It doesn't actually do this yet.

## Contributing

Right now, this code is pretty bare on features and there's a bit of duplication in the tests … and possibly some stupid design decisions. For the love of all that is holy, if you have ideas to build on this, send some love in the form of pull requests, 