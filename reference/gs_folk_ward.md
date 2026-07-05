# Calculate Folk and Ward graphical grain-size statistics

`gs_folk_ward()` calculates Folk and Ward graphical statistics from
boundary-interpolated grain-size percentiles. Percentiles follow the
package convention where `D_p` is the grain size at which `p` percent of
the sample is finer.

## Usage

``` r
gs_folk_ward(
  x,
  interpolation_scale = "phi",
  extrapolate = c("error", "warn_linear"),
  include_descriptions = TRUE
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- interpolation_scale:

  Interpolation scale passed to
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md).

- extrapolate:

  Extrapolation behavior passed to
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md).

- include_descriptions:

  Should descriptive Folk and Ward class labels be included?

## Value

A tibble with one row per sample and Folk and Ward graphical statistics.

## Details

The underlying `D_p` percentiles are computed by
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md),
including its deterministic tie-breaking rule for percentiles that fall
on a plateau caused by consecutive zero-retained classes (see
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
for details).
