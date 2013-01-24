## Version 0.4.3

- Made `Mapper#load_association!` more friendly. It now loads the associated objects for all objects passed in and works with arrays of referenced objects.
- `Mapper#load_association!` is also now more efficient — the N+1 queries have been optimized. The number of queries it fires off is now equal to the quantity of different classes of associated objects.
  - For example, if a user can have either a `UserProfile` or an `AdminProfile` as its `profile` attribute, Perpetuity will use two queries in `#load_association!` if and only if both types of profiles are used.
  - In that example, if you only query users with a `UserProfile`, only one DB query will be triggered.

New query example:

```ruby
user_mapper = Perpetuity[User]
users = user_mapper.all.to_a
user_mapper.load_association! users, :profile
```

Each of the users in the DB will have their profiles loaded with a single DB query per profile type and stored in their `profile` attributes.

## Version 0.4.2

- Improved speed and stability of `Mapper#first` and `Mapper#all`

## Version 0.4.1

- Add `Mapper#remove_index!` to remove DB indexes
- Fix index declarations in mappers to take unique/order options
  - These were intended to be there from the beginning, but the API wasn't made available in the mapper

## Version 0.4

- Mapper select DSL now more closely resembles `Enumerable` syntax
  - Instead of `mapper.select { published_at < Time.now }` you would write `mapper.select { |article| article.published_at < Time.now }`
  - It's a little more typing, but it eliminates a lot of problems that came from calling instance_exec on the block. It meant we couldn't call methods on the current object (they would be invoked on the `Query` object) or use instance variables from the current object.
  - Explained more in [issue #19](https://github.com/jgaskins/perpetuity/issues/19)

## Version 0.3.1

- Access object state via instance methods to store actual object state, rather than treating all objects as value objects
- Use `Object.allocate` rather than `Object.new` when restoring state to an object from the database

## Version 0.3

- Use `Perpetuity[]` instead of `Perpetuity::Mapper[]` to get mapper instances
- Allow subclassing of `Perpetuity::Mapper` with map macro
- Fix `select` calls using `id` as criteria from returning invalid or missing data
- Make MongoDB reads and writes fail fast
- Add indexing API to mappers
- Raise an exception when calling `Perpetuity[]` with a class that has no mapper
- Add unions and intersections to select queries for MongoDB adapter
  - This allows for queries like `Perpetuity[Article].select { (created_at < Time.now) & (published == true) }`
- Update object in memory when calling `Mapper#update`
- Add `Mapper#save` to update an object's current state in the DB. Previously, we only had `#update` (primarily for `update` actions in Rails controllers).
- Silenced some ugly warnings

*Version 0.2 and 0.1 have no changelog because I am a terrible developer*
