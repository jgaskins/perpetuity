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
