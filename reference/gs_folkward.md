# Calculate Folk and Ward graphical grain-size statistics

`gs_folkward()` is a compatibility alias for
[`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md).

## Usage

``` r
gs_folkward(
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
