## Version 0.6.2

- Make sure `Retrieval#first` limits the query to a single item
- Add `Mapper#sample`/`Retrieval#sample`
- Add `Retrieval#drop` to allow skipping a specific number of objects

## Version 0.6.1

- Fix reference equality bug

## Version 0.6.0

- Stop extending persisted/retrieved objects with `Perpetuity::PersistedObject`. Extending these objects invalidates method caches inside the VM, which degrades performance.
- Cache all objects returned from `Mapper#find(id)` by default into the mapper object. This can be bypassed with `Mapper#find(id, false)`
- Do not store uninitialized attributes with the MongoDB serializer. This shrinks the size of documents when possible.

## Version 0.5.0

- Allow querying based on referenced class/id or embedded-object data
- Remove duplicate references when loading associations on referenced objects
- Optimize loading associations with zero/one/many objects. It is similar to `Array#detect` vs `Array#select`. `detect` is faster if you only need one.
- Fixed a bug in defining methods on generated mapper classes which would mistakenly define them on the class instead of the mapper objects
- Add `none?`/`one?`/`all?`/`any?` methods to mappers.
- Add block functionality to `Mapper#count`, similar to `Enumerable#count`
- Alias `Mapper#find_all` to `Mapper#select`
- Alias `Mapper#detect` to `Mapper#find`
- Add `Mapper#reject` method to negate queries
- Allow `Mapper#find` to take a block like `Mapper#select`
- Add atomic incrementation

## Version 0.4.8

- Provide configuration one-liner ability for simple configs
- Memoize results for Retrieval objects
- `Retrieval#count` sends a count query rather than retrieving the result set and returning the count of the array
- Allow updating of objects that contain `Perpetuity::Reference`s to other persisted objects without first loading the association
- Fix bug preventing objects with an array of referenced objects from being updated
- Move serialization into the MongoDB adapter, allowing future adapters to implement their own serializations

## Version 0.4.7

- Use instance variables rather than attr_readers in IdentityMap (avoids calling methods during `load_association!`).
- Fixed a bug with MongoDB authentication.
- Use attribute names rather than a stringified attribute for MongoDB indexes.
- Fixed a bug with deserializing attributes of namespaced classes. — [Jaap Groeneveld](https://github.com/jgroeneveld)
- Fixed serialization of `Perpetuity::Reference` attributes caused by resaving an object that did not have all of its referenced associations loaded.

## Version 0.4.6

- Fix an inconsistency between `mongo` and `moped` gems. Previously, the MongoDB adapter relied on the fail-fast behavior of the `mongo` gem so we had no need to check for errors. Moped does not do that by default, which resulted in incorrect behavior of the gem when an object was not persisted.
- The `Mapper#select` DSL now allows the use of `!=` as criteria. Not all supported Ruby implementations allowed that operator to be overridden when the DSL was created, but they do now.

## Version 0.4.5

- Move from the `mongo` gem from 10gen to the `moped` gem for talking to MongoDB. This resulted in performance gains of 30-80%, depending on query size.
- Make persisted objects marshalable.
  - Previously, the `id` method was defined on individual objects that were either persisted to or retrieved from the DB. This made them unable to be marshaled with `Marshal.dump`.
  - Now we extend the objects with `Perpetuity::PersistedObject` to keep them marshalable while still providing `id`. This keeps them marshalable (unmarshalled objects will still be extended with `Perpetuity::PersistedObject`).
- Provided a partial fix for a [bug](https://github.com/jgaskins/perpetuity/issues/23) that kept us from being able to persist hash attributes properly. See the first comments in the linked GitHub issue for an explanation of why it is only a partial fix.
- Stopped testing on MRI 1.9.2 with Travis CI. Moped requires 1.9.3 or higher.

## Version 0.4.4

- Automatically persist all referenced objects if they are not already persisted. Previously, referenced objects were required to be persisted before persisting the referencing object.

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
