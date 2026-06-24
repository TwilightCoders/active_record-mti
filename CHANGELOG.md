# ActiveRecord::MTI

## 0.5.0 _(Unreleased)_
- **Rails 8.0 / 8.1 compatibility** — read the discriminator from the read-only
  `ActiveRecord::Result::IndexedRow` (no `#delete`) that Rails 7.2+/8.x passes to
  `discriminate_class_for_record`, bounding the STI-leaf recursion with a
  `mti_class != self` guard
- Guard empty-`INHERITS` `create_table` against a CHECK-constraint double-group:
  a column-less table with a CHECK already emits `(CONSTRAINT ...)`, so only inject
  the `()` column list when there are no columns **and** no check constraints
- Full **Rails 5.2 → 8.1** CI matrix (GitHub Actions), one row per Rails on the latest
  Ruby it supports; pin `pg ~> 1.5` on Ruby < 3.0; added Qlty config + coverage upload
- **Rails 7.1 compatibility** — fixed `_load_from_sql` override for Rails 7.1+
  which skips `discriminate_class_for_record` when the inheritance column is
  absent from the result set
- Fixed frozen `columns_hash` on Rails 7.0+ by replacing the hash instead of
  mutating it
- Fixed `build_tableoid_column` to handle the `new_column_from_field` arity
  change in Rails 7.1 (3 args instead of 2)
- Fixed `column_definitions` override to filter results rather than replacing
  the full SQL query — forward-compatible across Rails versions
- Fixed `pg_inherits` query to select specific columns (PG10+ added
  `inhdetachpending` which broke the struct)
- Fixed `create_table` to use `**kwargs` for Rails 7+ compatibility
- Fixed `postgresql_version` parsing for suffixed strings like "17.9 (Homebrew)"
- Replaced Thread monkey-patch with `ThreadContext` module
- Replaced `Hash#&` monkey-patch with inline set intersection
- Dropped `registry` gem dependency — uses plain Hash + Array#detect
- Added Gemfiles for Rails 6.0, 6.1, 7.0, 7.1, 7.2, 8.0, 8.1
- Bumped minimum Ruby to 2.7, minimum Rails to 5.2

## 0.4.0 _(Unreleased)_
- Major overhaul to improve injection hygiene and performance
  - Refactored to improve inheritance detection at boot
  - Simplified a lot of the core inheritance logic
  - Improved Registry of parent/child tables
- Removed `uses_mti`

## 0.3.0 _(Unreleased)_
- Greatly improved future-proofing injection strategy.
  - No longer overwriting (and maintaining) ActiveRecord Calculation sub-routines.
- Instead of injecting at `build_select`, we're injecting at `build_arel` with one additional new sub-routine (`build_mti`)
  - `build_mti` sub-routine detects if an MTI projection is needed based on grouping and selecting from query being built.
- No longer need to use `uses_mti`

## 0.2.1 _(September 20th 2017)_
- More reliable class discrimination
- Improved view support

## 0.1.1 _(June 23rd 2017)_
- Fixes issue where inheritance check is called multiple times.
- Can handle a (simple) view that references a table that uses MTI

## 0.1.0 _(May 12th 2017)_
- PSQL Adapter now responds to version
- Improved column pulls from DB

## 0.0.7 _(May 11th 2017)_
- Specs!
- Breaking Change: must call `uses_mti` in models
- MTI class discrimination happens before STI
- More reliable projection/unprojection
- Improved table_name inference

## 0.0.6 _(March 28th 2017)_
- Improve how `ActiveRecord::MTI` is injected into Rails

## 0.0.5 _(September 27th 2016)_
- Allow SQL calculations (like `sum` and `count`) to execute by removing unneeded MTI projections

## 0.0.2 _(September 21st 2016)_
- Default value to return when finding MTI class
