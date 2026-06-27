# Calculate additional grain-size indices

`gs_engineering()` is a compatibility alias for
[`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md).
It returns grain-size index values only; it does not implement complete
civil-engineering classification systems such as AASHTO or USCS.

## Usage

``` r
gs_engineering(
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
