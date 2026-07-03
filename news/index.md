# Changelog

## grainsizeR (development version)

- Started post-v0.1.0 development.
- Added a hardening roadmap for performance, workflow validation, naming
  consistency, documentation polish, and pre-Zenodo review.
- Improved texture workflow interoperability so official wide fraction
  outputs can feed USDA classification and USDA/GRADISTAT ternary
  plotting directly.
- `gravel_sand_mud` is now an independent GRADISTAT-compatible scheme
  using a 63 um sand/mud boundary, rather than an alias of
  `wentworth_major`. `wentworth_major` remains a strict Wentworth /
  phi-scale scheme using the 62.5 um sand/silt boundary.
- Updated bundled example grain-size CSV files to use 0.063 mm for the
  relevant fine boundary.
- Improved the performance of internal per-sample lookups used by
  [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md),
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md),
  [`gs_diagnostics()`](https://Gavin987.github.io/grainsizeR/reference/gs_diagnostics.md),
  [`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
  [`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
  [`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md),
  [`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md),
  and
  [`plot_trigon()`](https://Gavin987.github.io/grainsizeR/reference/plot_trigon.md)
  for inputs with many samples. Output is unchanged.

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
