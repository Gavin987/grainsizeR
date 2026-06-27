# Calculate additional grain-size indices

`gs_grain_size_indices()` calculates additional grain-size indices from
boundary-based D-value interpolation and a fine-content threshold.
Returned indices include coefficient of uniformity (`Cu`), coefficient
of curvature (`Cc`), Trask sorting, Trask skewness, fine content, and
fine equivalent.

## Usage

``` r
gs_grain_size_indices(
  x,
  fine_threshold_um = 62.5,
  interpolation_scale = "phi",
  extrapolate = "error"
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- fine_threshold_um:

  Fine-content threshold in micrometers.

- interpolation_scale:

  Interpolation scale passed to
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
  and
  [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

- extrapolate:

  Extrapolation behavior passed to
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
  and
  [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

## Value

A tibble with one row per sample and grain-size indices.
