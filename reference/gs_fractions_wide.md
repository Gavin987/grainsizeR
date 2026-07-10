# Calculate grain-size fraction percentages in wide form

`gs_fractions_wide()` is a convenience wrapper around
[`gs_fractions()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions.md)
that returns one row per sample with one percentage column per fraction
component. See
[`gs_fractions()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions.md)'s
Details for the nominal sieve-mesh equivalence table and the
pan-mass-aware below-boundary resolution logic this wrapper inherits
unchanged.

## Usage

``` r
gs_fractions_wide(
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
  [`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

- unresolved:

  Behavior when required thresholds cannot be calculated. `"warn_na"`
  warns and returns `NA` for affected components. `"error"` throws an
  error.

- extrapolate:

  Extrapolation behavior passed to
  [`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).
  The default `"error"` avoids silent extrapolation into open-ended
  terminal classes.

## Value

A tibble with one row per sample and component percentage columns.
