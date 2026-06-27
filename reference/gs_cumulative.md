# Build cumulative grain-size boundary curves

`gs_cumulative()` converts retained class data in a `gsd_tbl` into
finite class-boundary cumulative curves. The returned table contains one
row per finite boundary in each sample.

## Usage

``` r
gs_cumulative(x)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

## Value

A tibble with sample identifiers, finite grain-size boundaries, and
cumulative percent finer and coarser values at each boundary.
