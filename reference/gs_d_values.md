# Calculate grain-size percentiles

`gs_d_values()` estimates `D_p`, the grain size at which `p` percent of
a sample is finer. Interpolation is based on finite class boundaries
from
[`gs_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/gs_cumulative.md),
not class midpoints.

## Usage

``` r
gs_d_values(
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

## Details

Some samples contain a run of consecutive classes with zero retained
mass (e.g. several sieve apertures with nothing caught between them),
which produces an exact tie in cumulative percent finer across those
boundaries. When a requested percentile falls between such a tied
plateau and an adjacent distinct value, `gs_d_values()` resolves the tie
deterministically: it brackets against the member of the tied plateau
nearest the real transition (the finest boundary of a plateau being
approached from below, or the coarsest boundary of a plateau being
approached from above), rather than depending on incidental input row
order. This is a fixed, documented rule, not an implementation detail
that may vary between calls or package versions.
