# Changelog

## grainsizeR 0.2.0.9000

### Development version

- Started post-0.2.0 development.
- Fixed a correctness issue in percentile interpolation: when a sample
  has a run of consecutive classes with zero retained mass (e.g. several
  sieve apertures with nothing caught between them), cumulative percent
  finer ties exactly across those classes. Requested percentiles (or
  percent-finer thresholds) falling on such a tied plateau are now
  resolved by an explicit, deterministic tie-breaking rule instead of
  depending on incidental input row order. Affects
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md),
  [`gs_percentile()`](https://Gavin987.github.io/grainsizeR/reference/gs_percentile.md),
  and everything built on them
  ([`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
  [`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md),
  [`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
  [`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md),
  [`gs_diagnostics()`](https://Gavin987.github.io/grainsizeR/reference/gs_diagnostics.md),
  [`plot_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/plot_cumulative.md),
  [`plot_gradistat_summary()`](https://Gavin987.github.io/grainsizeR/reference/plot_gradistat_summary.md)).
  Results for samples without tied cumulative values are unchanged.

## grainsizeR 0.2.0

### Breaking changes

- `gravel_sand_mud` is no longer an alias of `wentworth_major`. It is
  now an independently defined, GRADISTAT-compatible fraction scheme
  using a 63 um sand/mud boundary (Blott & Pye rounding convention), so
  its `mud_percent` now matches the `gradistat` scheme’s
  `silt_percent + clay_percent` exactly.
  `wentworth_major`/`wentworth_detailed` are unchanged and keep the
  strict Udden-Wentworth phi-scale boundary (62.5 um = 1/16 mm). If your
  code assumed `gravel_sand_mud` and `wentworth_major` returned
  identical fractions, pick the scheme matching the boundary convention
  you intend.
- Bundled example files `inst/extdata/grain.wide.csv` and
  `grain.long.csv` now use a 0.063 mm (previously 0.0625 mm)
  fine-boundary value, consistent with the `gravel_sand_mud` change
  above. Sample IDs and all other values are unchanged.

### New features

- GRADISTAT and USDA official
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md)
  output can now be fed directly into
  [`classify_texture()`](https://Gavin987.github.io/grainsizeR/reference/classify_texture.md)
  and both ternary plot functions
  ([`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)/[`plot_texture_triangle()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_triangle.md))
  without manual reshaping.

### Performance

- Optimized internal per-sample lookups used by
  [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md),
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md),
  [`gs_diagnostics()`](https://Gavin987.github.io/grainsizeR/reference/gs_diagnostics.md),
  [`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
  [`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
  [`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md),
  [`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md),
  and
  [`plot_trigon()`](https://Gavin987.github.io/grainsizeR/reference/plot_trigon.md)
  for inputs with many samples (measured ~15-40% faster on realistic
  sample counts). Output values are unchanged.

### Documentation and internal changes

- Clarified `README`/vignette documentation of the `gravel_sand_mud` vs.
  `wentworth_major` boundary conventions and reduced repetitive phrasing
  in several vignettes.
- Removed an unused internal helper (`fraction_scheme_alias()`) with no
  remaining callers.
- Added an automated test (`tests/testthat/test-readme-examples.R`) that
  runs README’s example code and checks it still works, since README’s
  code chunks are not evaluated when the page is rendered.

## grainsizeR 0.1.0

- Initial public release of grainsizeR.
- Added long and wide grain-size CSV import workflows.
- Added `gsd_tbl` validation and unit-normalized grain-size
  representation.
- Added D-values, Folk and Ward statistics, moment statistics, modes,
  descriptors, diagnostics, and quality flags.
- Added fraction schemes including Wentworth major/detailed, USDA,
  GRADISTAT, and regional soil texture schemes.
- Added GRADISTAT and USDA ternary plotting workflows.
- Added distribution, cumulative, fraction, and ternary plotting
  functions.
- Added bundled example CSV files for reproducible README and vignette
  workflows.
- Standardized texture classification output names as `texture_class_id`
  and `texture_class`.
- Standardized USDA texture workflows under the public scheme name
  `usda`.
- Prepared GitHub pre-release documentation and repository templates.
