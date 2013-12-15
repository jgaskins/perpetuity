# Perpetuity [![Build Status](https://secure.travis-ci.org/jgaskins/perpetuity.png)](http://travis-ci.org/jgaskins/perpetuity) [![Code Climate](https://codeclimate.com/github/jgaskins/perpetuity.png)](https://codeclimate.com/github/jgaskins/perpetuity)

Perpetuity is a simple Ruby object persistence layer that attempts to follow Martin Fowler's Data Mapper pattern, allowing you to use plain-old Ruby objects in your Ruby apps in order to decouple your domain logic from the database as well as speed up your tests. There is no need for your model classes to inherit from another class or even include a mix-in.

Your objects will hopefully eventually be able to be persisted into whichever database you like. Right now, only MongoDB is supported. There is also a [PostgreSQL adapter](https://github.com/jgaskins/perpetuity-postgres) under heavy development (nearly up-to-date with the [MongoDB adapter](https://github.com/jgaskins/perpetuity-mongodb)). Other persistence solutions will come later.

## How it works

In the Data Mapper pattern, the objects you work with don't understand how to persist themselves. They interact with other objects just as in any other object-oriented application, leaving all persistence logic to mapper objects. This decouples them from the database and allows you to write your code without it in mind.

## Installation

Add the following to your Gemfile and run `bundle` to install it.

```ruby
gem 'perpetuity/mongodb', '~> 1.0.0.beta'  # if using MongoDB
gem 'perpetuity/postgres'                  # if using Postgres
```

Note that you do not need to explicitly declare the `perpetuity` gem as a dependency. The database adapter takes care of that for you. It works just like including `rspec-rails` into your Rails app.

## Configuration

The only currently-1.0-quality adapter is MongoDB, but stay tuned for the [Postgres adapter](https://github.com/jgaskins/perpetuity-postgres). The simplest configuration is with the following line:

```ruby
Perpetuity.data_source :mongodb, 'my_mongo_database'
Perpetuity.data_source :postgres, 'my_pg_database'
```

*Note:* You cannot use different databases in the same app like that. At least, not yet. :-) Possibly a 1.1 feature?

If your database is on another server/port or you need authentication, you can specify those as options:

```ruby
Perpetuity.data_source :mongodb, 'my_database', host: 'mongo.example.com',
                                                port: 27017,
                                                username: 'mongo',
                                                password: 'password'
```

If you are using Perpetuity with a multithreaded application, you can specify a `:pool_size` parameter to set up a connection pool. If you omit this parameter, it will use the data source's default pool size.

## Setting up object mappers

Object mappers are generated by the following:

```ruby
Perpetuity.generate_mapper_for MyClass do
  attribute :my_attribute
  attribute :my_other_attribute

  index :my_attribute
end
```

The primary mapper configuration will be configuring attributes to be persisted. This is done using the `attribute` method. Calling `attribute` will add the specified attribute and its class to the mapper's attribute set. This is how the mapper knows what to store and how to store it. Here is an example of an `Article` class, its mapper and how it can be saved to the database.

Accessing mappers after they've been generated is done through the use of the subscript operator on the `Perpetuity` module. For example, if you generate a mapper for an `Article` class, you can access it by calling `Perpetuity[Article]`.

```ruby
class Article
  attr_accessor :title, :body
end

Perpetuity.generate_mapper_for Article do
  attribute :title
  attribute :body
end

article = Article.new
article.title = 'New Article'
article.body = 'This is an article.'

Perpetuity[Article].insert article
```

## Loading Objects

You can load all persisted objects of a particular class by sending `all` to the mapper object. Example:

```ruby
Perpetuity[Article].all
```

You can load specific objects by calling the `find` method with an ID param on the mapper and passing in the criteria. You may also specify more general criteria using the `select` method with a block similar to `Enumerable#select`.

```ruby
article  = Perpetuity[Article].find params[:id]
users    = Perpetuity[User].select { |user| user.email == 'me@example.com' }
articles = Perpetuity[Article].select { |article| article.published_at < Time.now }
comments = Perpetuity[Comment].select { |comment| comment.article_id.in articles.map(&:id) }
```

These methods will return a Perpetuity::Retrieval object, which will lazily retrieve the objects from the database. They will wait to hit the DB when you begin iterating over the objects so you can continue chaining methods, similar to ActiveRecord.

```ruby
article_mapper = Perpetuity[Article]
articles = article_mapper.select { |article| article.published_at < Time.now }
                         .sort(:published_at)
                         .reverse
                         .page(2)
                         .per_page(10) # built-in pagination

articles.each do |article| # This is when the DB gets hit
  # Display the pretty articles
end
```

Unfortunately, due to limitations in the Ruby language itself, we cannot get a true `Enumerable`-style select method. The limitation shows itself when needing to have multiple criteria for a query, as in this super-secure example:

```ruby
user = Perpetuity[User].select { |user| (user.email == params[:email]) & (user.password == params[:password]) }
```

Notice that we have to use a single `&` and surround each criterion with parentheses. If we could override `&&` and `||`, we could put more Rubyesque code in here, but until then, we have to operate within the boundaries of the operators that can be overridden.

## Associations with Other Objects

The database can natively serialize some objects. For example, MongoDB can serialize `String`, `Numeric`, `Array`, `Hash`, `Time`, `nil`, `true`, `false`, and a few others. For other objects, you must determine whether you want those attributes embedded within the same document in the database or attached as a reference. For example, a `Post` could have `Comment`s, which would likely be embedded within the post object. But these comments could have an `author` attribute that references the `Person` that wrote the comment. Embedding the author in this case is not a good idea since it would be a duplicate of the `Person` that wrote it, which would then be out of sync if the original object is modified.

If an object references another type of object, the association is declared just as any other attribute. No special treatment is required. For embedded relationships, make sure you use the `embedded: true` option in the attribute.

```ruby
Perpetuity.generate_mapper_for Article do
  attribute :title
  attribute :body
  attribute :author
  attribute :comments, embedded: true
  attribute :timestamp
end

Perpetuity.generate_mapper_for Comment do
  attribute :body
  attribute :author
  attribute :timestamp
end
```

In this case, the article has an array of `Comment` objects, which the serializer knows that the data source cannot serialize. It will then tell the `Comment` mapper to serialize it and it stores that within the array.

If some of the comments aren't objects of class `Comment`, it will adapt and serialize them according to their class. This works very well for objects that can have attributes of various types, such as a `User` having a profile attribute that can be either a `UserProfile` or `AdminProfile` object. You don't need to declare anything different for this case, just store the appropriate type of object into the `User`'s `profile` attribute and the mapper will take care of the details.

If the associated object's class has a mapper defined, it will be used by the parent object's mapper for serialization. Otherwise, the object will be `Marshal.dump`ed. If the object cannot be marshaled, the object cannot be serialized and an exception will be raised.

When you load an object that has embedded associations, the embedded attributes are loaded immediately. For referenced associations, though, only the object itself will be loaded. All referenced objects must be loaded with the `load_association!` mapper call.

```ruby
user_mapper = Perpetuity[User]
user = user_mapper.find(params[:id])
user_mapper.load_association! user, :profile
```

This loads up the user's profile and injects it into the profile attribute. All loading of referenced objects is explicit so that we don't load an entire object graph unnecessarily. This encourages (forces, really) you to think about all of the objects you'll be loading.

If you want to load a 1:N, N:1 or M:N association, Perpetuity handles that for you.

```ruby
article_mapper = Perpetuity[Article]
articles = article_mapper.all.to_a
article_mapper.load_association! articles.first, :tags # 1:N
article_mapper.load_association! articles, :author     # All author objects for these articles load in a single query - N:1
article_mapper.load_association! articles, :tags       # M:N
```

Each of these `load_association!` calls will only execute the number of queries necessary to retrieve all of the objects. For example, if the `author` attribute for the selected articles contains both `User` and `Admin` objects, it will execute two queries (one each for `User` and `Admin`). If the tags for all of the selected articles are all `Tag` objects, only one query will be executed even in the M:N case.

## Customizing persistence

Setting the ID of a record to a custom value rather than using the DB default.

```ruby
Perpetuity.generate_mapper_for Article do
  id { title.gsub(/\W+/, '-') } # use the article's parameterized title attribute as its ID
end
```

The block passed to the `id` macro is evaluated in the context of the object being persisted. This allows you to use the object's private methods and instance variables if you need to.

## Indexing

Indexes are declared with the `index` method. The simplest way to create an index is just to pass the attribute to be indexed as a parameter:

```ruby
Perpetuity.generate_mapper_for Article do
  index :title
end
```

The following will generate a unique index on an `Article` class so that two articles cannot be added to the database with the same title. This eliminates the need for uniqueness validations (like ActiveRecord has) that check for existence of that value. Uniqueness validations have race conditions and don't protect you at the database level. Using unique indexes is a superior way to do this.

```ruby
Perpetuity.generate_mapper_for Article do
  index :title, unique: true
end
```

Also, some databases provide the ability to specify an order for the index. For example, if you want to query your blog with articles in descending order, you can specify a descending-order index on the timestamp for increased query performance.

```ruby
Perpetuity.generate_mapper_for Article do
  index :timestamp, order: :descending
end
```

### Applying indexes

It's very important to keep in mind that specifying an index does not create it on the database immediately. If you did this, you could potentially introduce downtime every time you specify a new index and deploy your application. Additionally, if a unique index fails to apply, you would not be able to start your app.

In order to apply indexes to the database, you must send `reindex!` to the mapper. For example:

```ruby
class ArticleMapper < Perpetuity::Mapper
  map Article
  attribute :title
  index :title, unique: true
end

Perpetuity[Article].reindex!
```

You could put this in a rake task to be executed when you deploy your app.

## Rails Integration

Let's face it, most Ruby apps run on Rails, so we need to be able to support it. Beginning with 0.7.0, Perpetuity automatically detects Rails when you configure it and will load Rails support at that point.

### Dynamic mapper reloading

Previous versions of Perpetuity would break when Rails reloaded your models in development mode due to class objects being different. It now reloads mappers dynamically based on whether the class has been reloaded.

In order for this to work, your mapper files need to be named `*_mapper.rb` and be stored anywhere inside your project's `app` directory. Usually, this would be `app/mappers`, but this is not enforced.

### ActiveModel-compliant API

Perpetuity deals with POROs just fine but Rails does not. This is why you have to include `ActiveModel::Model` in your objects that you want to pass to various Rails methods (such as `redirect_to`, `form_for` and `render`).

In your models, including `ActiveModel::Model` in Rails 4 (or the underlying modules in Rails 3) will give you the API that Rails expects but that won't work with Perpetuity. For example, ActiveModel assumes an `id` method but your model may not provide it, so instead of including ActiveModel we provide a `RailsModel` mixin.

```ruby
class Person
  include Perpetuity::RailsModel
end
```

This will let Rails know how to talk to your models in the way that Perpetuity handles them.

## Contributing

There are plenty of opportunities to improve what's here and possibly some design decisions that need some more refinement. You can help. If you have ideas to build on this, send some love in the form of pull requests, issues or [tweets](http://twitter.com/jamie_gaskins) and I'll do what I can for them.
