# Calculate grain-size percentiles

`gs_percentile()` is a compatibility alias for
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md).

## Usage

``` r
gs_percentile(
  x,
  probs = c(5, 10, 16, 25, 30, 50, 60, 75, 84, 90, 95),
  interpolation_scale = c("phi", "log_um", "linear_um"),
  output_unit = c("um", "mm", "phi"),
  extrapolate = c("error", "warn_linear"),
  scale = NULL
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- probs:

  Numeric vector of percentiles on the 0-100 scale.

- interpolation_scale:

  Interpolation scale. `"phi"` interpolates in phi units, `"log_um"`
  interpolates in log10 micrometers, and `"linear_um"` interpolates
  directly in micrometers.

- output_unit:

  Preferred reporting unit. The returned table always includes
  micrometer, millimeter, and phi columns.

- extrapolate:

  Behavior when a requested percentile falls outside the observed finite
  boundary curve. `"error"` throws an error, and `"warn_linear"` warns
  and linearly extrapolates on the selected scale.

- scale:

  Compatibility alias for `interpolation_scale`.

## Value

A tibble with one row per sample and requested percentile.
