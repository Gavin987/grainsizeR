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
  [`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md)
  and
  [`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

- extrapolate:

  Extrapolation behavior passed to
  [`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md)
  and
  [`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

## Value

A tibble with one row per sample and grain-size indices.

## Details

D10/D25/D30/D50/D60/D75 are computed by
[`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md),
including its deterministic tie-breaking rule for percentiles that fall
on a plateau caused by consecutive zero-retained classes (see
[`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md)
for details); `fine_content_percent` is computed by
[`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md),
which is not affected by that tie-breaking rule (see its documentation).
