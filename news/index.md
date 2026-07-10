# Changelog

## grainsizeR 0.3.0

### User-visible fixes and behavior changes

- Percentile interpolation now uses an explicit deterministic
  tie-breaking rule when consecutive zero-retained classes create
  duplicate cumulative percent-finer values. Requested percentiles or
  percent-finer thresholds on these tied plateaus no longer depend on
  incidental input row order. This affects
  [`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md),
  [`gs_percentile()`](https://gavin987.github.io/grainsizeR/reference/gs_percentile.md),
  and functions built on the same percentile path. Results for samples
  without tied cumulative values are unchanged.
- [`gs_fractions()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions.md)
  and
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md)
  now handle thresholds below a sample’s finest finite boundary
  consistently with
  [`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).
  When an open lower tail contains nonzero retained mass, the default
  `extrapolate = "error"` no longer silently reports 0 percent; callers
  may opt into `extrapolate = "warn_linear"` for a warned linear
  extrapolation. When the open lower tail is genuinely empty, exact 0
  percent results are unchanged.
- Added documented nominal sieve-mesh equivalence handling for 0.0625 mm
  and 0.063 mm. This is scoped to real sieve workflows and documented
  mesh designations, not mathematical equality. It lets fraction and
  percent-finer calls resolve thresholds through an equivalent measured
  boundary when no genuine finer-resolution data lie between the
  requested threshold and the sample boundary.

### New output and methods

- Added the Krumbein (1938) quartile deviation as
  `quartile_deviation_phi` in
  [`gs_d_spread()`](https://gavin987.github.io/grainsizeR/reference/gs_d_spread.md)
  and in
  [`gs_parameters()`](https://gavin987.github.io/grainsizeR/reference/gs_parameters.md)
  when `parameters = "d_spread"`. The value is reported in phi units as
  `Qd = (D25_phi - D75_phi) / 2`. Existing
  [`gs_d_spread()`](https://gavin987.github.io/grainsizeR/reference/gs_d_spread.md)
  and
  [`gs_parameters()`](https://gavin987.github.io/grainsizeR/reference/gs_parameters.md)
  columns are unchanged.

### Performance

- [`gs_parameters()`](https://gavin987.github.io/grainsizeR/reference/gs_parameters.md)
  now reuses shared cumulative curves, unioned percentile tables, and
  raw sample splits internally for selected parameter groups. This
  reduces repeated work in mixed
  [`gs_parameters()`](https://gavin987.github.io/grainsizeR/reference/gs_parameters.md)
  calls while preserving standalone public function behavior and
  signatures.
- The refactor is intentionally internal. It should not be read as a
  universal speed advantage; measured gains depend on the requested
  parameter groups and input size.

### Tests and hygiene

- Expected test warnings are now asserted or narrowly muffled so
  intentional warnings do not leak into the global testthat warning
  count.
- The full test suite is expected to report `WARN 0`.

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
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md)
  output can now be fed directly into
  [`classify_texture()`](https://gavin987.github.io/grainsizeR/reference/classify_texture.md)
  and both ternary plot functions
  ([`plot_texture_ternary()`](https://gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)/[`plot_texture_triangle()`](https://gavin987.github.io/grainsizeR/reference/plot_texture_triangle.md))
  without manual reshaping.

### Performance

- Optimized internal per-sample lookups used by
  [`gs_fractions()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions.md),
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md),
  [`gs_diagnostics()`](https://gavin987.github.io/grainsizeR/reference/gs_diagnostics.md),
  [`gs_folk_ward()`](https://gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
  [`gs_grain_size_indices()`](https://gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
  [`gs_d_spread()`](https://gavin987.github.io/grainsizeR/reference/gs_d_spread.md),
  [`gs_parameters()`](https://gavin987.github.io/grainsizeR/reference/gs_parameters.md),
  and
  [`plot_trigon()`](https://gavin987.github.io/grainsizeR/reference/plot_trigon.md)
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
