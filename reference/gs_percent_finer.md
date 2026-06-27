# Calculate percent finer than grain-size thresholds

`gs_percent_finer()` returns the cumulative percent finer than one or
more requested grain-size thresholds for each sample. Values are taken
exactly from finite boundaries when thresholds match them, otherwise
they are interpolated between finite class boundaries on the selected
scale. This is the function used by grainsizeR to estimate percent finer
at arbitrary particle-size thresholds such as 2, 20, 50, 60, and 63 um;
requested thresholds do not need to match measured class boundaries.

## Usage

``` r
gs_percent_finer(
  x,
  sizes,
  size_unit = "um",
  interpolation_scale = c("phi", "log_um", "linear_um"),
  extrapolate = c("error", "warn_linear"),
  scale = NULL
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- sizes:

  Numeric vector of grain-size thresholds.

- size_unit:

  Unit for `sizes`. Supported values are `"um"`, `"mm"`, and `"phi"`.

- interpolation_scale:

  Interpolation scale. `"phi"` interpolates in phi units, `"log_um"`
  interpolates in log10 micrometers, and `"linear_um"` interpolates
  directly in micrometers.

- extrapolate:

  Behavior when a requested threshold falls outside the observed finite
  boundary size range, including thresholds inside open-ended terminal
  classes. `"error"` throws an error, and `"warn_linear"` warns,
  linearly extrapolates on the selected scale, and marks affected rows
  with `extrapolated = TRUE`.

- scale:

  Compatibility alias for `interpolation_scale`.

## Value

A tibble with one row per sample and requested threshold.

## Details

Interpolation is based on
[`gs_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/gs_cumulative.md).
Terminal open-ended fine or coarse classes are not silently treated as
bounded intervals. Thresholds that fall inside an open-ended terminal
class are unresolved with `extrapolate = "error"` and are linearly
extrapolated with a warning only when `extrapolate = "warn_linear"`.
