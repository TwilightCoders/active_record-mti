# ActiveRecord::MTI

## 0.4.0 _(Unreleased)_
- Refactored to improve inheritance detection at boot
  - Checks mti_table_name for table presence, falls back to regular table_name
  - Doesn't trample as much naming
  - Registry of parent/child tables
  - improved future-proofing injection strategy.
- Simplified the query logic
  - No longer overwriting (and maintaining) ActiveRecord Calculation sub-routines.
  - Instead of injecting at `build_select`, we're injecting at `build_arel` with `build_mti` wrapper sub-routine
  - `build_mti` sub-routine detects if an MTI projection is needed based on grouping and selecting from query being built.
- Removed `uses_mti`

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
