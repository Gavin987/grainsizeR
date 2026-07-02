# Calculate grain-size fraction percentages

`gs_fractions()` calculates sediment or soil fraction percentages using
a named built-in particle-size scheme. Schemes are treated as complete,
non-overlapping particle-size partitions. Fractions are calculated from
cumulative percent-finer values at scheme thresholds by calling
[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
for thresholds inside the observed finite size range.

## Usage

``` r
gs_fractions(
  x,
  scheme = "wentworth_major",
  normalize = c("none", "fine_earth"),
  interpolation_scale = "phi",
  unresolved = c("warn_na", "error"),
  extrapolate = "error"
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- scheme:

  Built-in fraction scheme name.

- normalize:

  Normalization mode. `"none"` returns whole-sample percentages.
  `"fine_earth"` requires a scheme with a `gravel` component, excludes
  gravel rows, and normalizes the remaining non-gravel fractions against
  the non-gravel total.

- interpolation_scale:

  Interpolation scale passed to
  [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

- unresolved:

  Behavior when required thresholds cannot be calculated. `"warn_na"`
  warns and returns `NA` for affected components. `"error"` throws an
  error.

- extrapolate:

  Extrapolation behavior passed to
  [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).
  The default `"error"` avoids silent extrapolation into open-ended
  terminal classes.

## Value

A tibble with one row per sample and scheme component.

## Details

Scheme thresholds do not need to match observed grain-size boundaries.
When thresholds such as 0.002, 0.020, 0.050, 0.060, or 0.063 mm are
bracketed by finite class boundaries, percent-finer values are
interpolated on the cumulative curve. Fraction and texture functions
automatically use the normalized particle-size scale from `gsd_tbl`;
users do not need to specify millimetres or micrometres after import.
Thresholds above the largest observed finite boundary resolve to 100
percent finer, and thresholds below the smallest observed finite
boundary resolve to 0 percent finer. This returns absent particle-size
classes as zero rather than `NA`, so complete schemes close to 100
percent for samples whose retained percentages sum to 100. `NA` is
reserved for thresholds that are genuinely unresolved inside the finite
observed size range. Fraction schemes do not extrapolate unless
`extrapolate = "warn_linear"` is passed explicitly.
