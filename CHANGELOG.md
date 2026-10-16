# ActiveRecord::MTI

## 0.5.0 _(Unreleased)_
- **`tableoid` is a virtual attribute again, never a table column.** Listing it among the
  columns put it into every INSERT once partial inserts are off (the Rails 7+ default), and
  PostgreSQL refuses to write a system column (`PG::UndefinedColumn`).
- **Loading a schema with `create_table inherits:` no longer fails with `PG::DuplicateTable`.** A
  dumped schema declares the child's copy of each inherited index inside the child's
  `create_table`, and the inherited copy was then created again. An index the child already has
  under that name is now left alone.
- **`pluck` no longer returns `[value, tableoid]` tuples.**

  `build_mti` projects `tableoid` onto every relation so MTI can discriminate a row's real
  class. `pluck` asks for an explicit column list, returns raw values, needs no discrimination —
  and faithfully returned whatever the relation projected, so every pluck on an MTI model
  silently returned N+1 values per row:

  ```ruby
  Evidence.pluck(:evidence_type)        # => [["summarizes", 210031], ...]
  Conversation.pluck(:provider)         # => [["claude_code", 113248], ...]
  Evidence.pluck(:evidence_type, :note) # => [["summarizes", nil, 210031], ...]
  # SELECT "evidence"."evidence_type", "evidence"."tableoid" FROM ONLY evidence
  ```

  Affected every column type — it was never uuid-specific — and was NOT avoided by
  `from("ONLY …")` or by `pluck(Arel.sql(...))`; the projection is appended after the caller's
  select list either way. The only safe forms were `map(&:attr)` and raw `select_values`.

  It fails silently and plausibly, which is what makes it expensive rather than annoying:
  `id == x` is simply false, `include?` simply misses, `uniq` simply doesn't dedupe, and nothing
  raises. In one consuming app it produced a measurement reading "0 agreements, 37
  disagreements" between two id sets that in truth agreed 33 times with zero disagreements — a
  result that read as a real architectural problem. It caught four separate work streams there
  in a single day, twice within one hour to someone who had already read a warning comment about
  it. Documenting the trap had been tried, twice, and had failed both times; that is why the fix
  belongs at the producer, where a caller cannot get it wrong.

  It also silently corrupted LLM input in that app: a groomer built its extraction prompt from
  `Entity.pluck(:name)`, joined into *"Known entities (use these names exactly when referring to
  them)"*, which rendered as `overlanding technology company, 113295, Claude, 113295, Legal
  Framework, 113295…` — every real name followed by the tableoid, instructing the model to treat
  a table OID as an entity name. (No numerically-named entities were ever created, so the
  visible damage was nil; the cost was noise in the instruction, which can't be measured after
  the fact.)

  Suppression is scoped to the duration of a `pluck` via `ThreadContext.with`, exactly as
  `#perform_calculation` already scopes the tableoid CAST for calculations. The discrimination
  mechanism is untouched: an ordinary relation still projects `tableoid`, a child row still
  discriminates to its real class, and `tableoid` remains readable on a loaded record — all
  three asserted in `spec/active_record/mti/pluck_spec.rb`, which also fails if the suppression
  is removed.
- **`ids` no longer returns `[id, tableoid]` tuples** on Rails 7.1+, where `ids` builds its own
  query from the relation's arel instead of calling `pluck`; it gets the same scoped suppression
- Integrated the `datalayer` line (Rails 8.1 overhaul) into `develop`; where both lines
  fixed the same defect, the cross-version implementation from `develop` is kept
- Prepend `MTI::Relation` once onto `ActiveRecord::Relation` instead of into each model's
  relation delegate cache, so `tableoid` projection no longer depends on the order in which
  relations are first built (`build_mti` is a no-op for non-MTI models)
- Discrimination is independent of class-load order: `tableoid?` resolves `mti?` (which
  registers the class's oid) before checking the calculation flag, and a registry miss
  self-heals by resolving the oid through the catalog to its loaded class (preferring the
  table's STI base over an STI leaf)
- Patch `PostgreSQLAdapter` whenever it loads: via the `:active_record_postgresqladapter`
  hook on Rails 7.1+, and by loading it with ActiveRecord on Rails < 7.1 (which has no
  such hook), so MTI works regardless of gem load order
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
