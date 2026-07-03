# grainsizeR 0.2.0.9000

## Development version

- Started post-0.2.0 development.

# grainsizeR 0.2.0

## Breaking changes

- `gravel_sand_mud` is no longer an alias of `wentworth_major`. It is now an
  independently defined, GRADISTAT-compatible fraction scheme using a 63 um
  sand/mud boundary (Blott & Pye rounding convention), so its `mud_percent`
  now matches the `gradistat` scheme's `silt_percent + clay_percent` exactly.
  `wentworth_major`/`wentworth_detailed` are unchanged and keep the strict
  Udden-Wentworth phi-scale boundary (62.5 um = 1/16 mm). If your code
  assumed `gravel_sand_mud` and `wentworth_major` returned identical
  fractions, pick the scheme matching the boundary convention you intend.
- Bundled example files `inst/extdata/grain.wide.csv` and `grain.long.csv`
  now use a 0.063 mm (previously 0.0625 mm) fine-boundary value, consistent
  with the `gravel_sand_mud` change above. Sample IDs and all other values
  are unchanged.

## New features

- GRADISTAT and USDA official `gs_fractions_wide()` output can now be fed
  directly into `classify_texture()` and both ternary plot functions
  (`plot_texture_ternary()`/`plot_texture_triangle()`) without manual
  reshaping.

## Performance

- Optimized internal per-sample lookups used by `gs_fractions()`,
  `gs_fractions_wide()`, `gs_diagnostics()`, `gs_folk_ward()`,
  `gs_grain_size_indices()`, `gs_d_spread()`, `gs_parameters()`, and
  `plot_trigon()` for inputs with many samples (measured ~15-40% faster on
  realistic sample counts). Output values are unchanged.

## Documentation and internal changes

- Clarified `README`/vignette documentation of the `gravel_sand_mud` vs.
  `wentworth_major` boundary conventions and reduced repetitive phrasing in
  several vignettes.
- Removed an unused internal helper (`fraction_scheme_alias()`) with no
  remaining callers.
- Added an automated test (`tests/testthat/test-readme-examples.R`) that runs
  README's example code and checks it still works, since README's code
  chunks are not evaluated when the page is rendered.

# grainsizeR 0.1.0

- Initial public release of grainsizeR.
- Added long and wide grain-size CSV import workflows.
- Added `gsd_tbl` validation and unit-normalized grain-size representation.
- Added D-values, Folk and Ward statistics, moment statistics, modes,
  descriptors, diagnostics, and quality flags.
- Added fraction schemes including Wentworth major/detailed, USDA, GRADISTAT,
  and regional soil texture schemes.
- Added GRADISTAT and USDA ternary plotting workflows.
- Added distribution, cumulative, fraction, and ternary plotting functions.
- Added bundled example CSV files for reproducible README and vignette
  workflows.
- Standardized texture classification output names as `texture_class_id` and
  `texture_class`.
- Standardized USDA texture workflows under the public scheme name `usda`.
- Prepared GitHub pre-release documentation and repository templates.
