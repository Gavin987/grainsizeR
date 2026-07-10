# Calculate additional grain-size indices

`gs_engineering()` is a compatibility alias for
[`gs_grain_size_indices()`](https://gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md).
It returns grain-size index values only; it does not implement complete
civil-engineering classification systems such as AASHTO or USCS.

## Usage

``` r
gs_engineering(...)
```

## Arguments

- ...:

  Arguments forwarded to
  [`gs_grain_size_indices()`](https://gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md).

## Value

A tibble with one row per sample and grain-size indices.
