# ActiveRecord::MTI

## 0.3.0 _(November 7th 2017)_
- Greatly improved future-proofing injection strategy.
  - No longer overwriting (and maintaining) ActiveRecord Calculation sub-routines.
- Instead of injecting at `build_select`, we're injecting at `build_arel` with one additional new sub-routine (`build_mti`)
  - `build_mti` sub-routine detects if an MTI projection is needed based on grouping and selecting from query being built.

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
