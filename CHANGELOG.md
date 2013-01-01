## Version 0.3

- Add `Mapper#save` to update an object's current state in the DB
- Fix `select` calls using `id` as criteria
- Switch from `Mongo::Connection` to `Mongo::MongoClient`
  - This makes MongoDB reads and writes fail fast
- Add indexing interface
- Silence warnings
- Raise when calling Mapper[] with unmapped class
- Add unions and intersections to select queries for MongoDB adapter
  - This allows for queries like `Perpetuity[Article].select { (created_at < Time.now) & (published == true) }`
- Update object in memory when calling `Mapper#update`
- Allow subclassing of `Perpetuity::Mapper` with map macro
- Use `Perpetuity[]` instead of `Perpetuity::Mapper[]` to get mapper instances

*Version 0.2 and 0.1 have no changelog because I am a terrible developer*
