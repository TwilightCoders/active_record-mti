# ActiveRecord::MTI

## 0.4.0 _(Unreleased)_
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

  Suppression is scoped to the duration of a `pluck` via `Thread.currently`, exactly as
  `#perform_calculation` already scopes the tableoid CAST for calculations. The discrimination
  mechanism is untouched: an ordinary relation still projects `tableoid`, a child row still
  discriminates to its real class, and `tableoid` remains readable on a loaded record — all
  three asserted in `spec/active_record/mti/pluck_spec.rb`, which also fails if the suppression
  is removed.
- Major overhaul to improve injection hiegine and performance
  - Refactored to improve inheritance detection at boot
  - Simplified a lot of the core inheritence logic
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
