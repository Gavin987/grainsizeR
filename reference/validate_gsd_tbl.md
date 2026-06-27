# Validate a grain-size distribution tibble

`validate_gsd_tbl()` checks that an object has the required `gsd_tbl`
columns, that open-ended class flags and boundaries are internally
consistent, and optionally that retained percentages sum to
approximately 100 within each sample.

## Usage

``` r
validate_gsd_tbl(x, check_sum = TRUE, tolerance = 1e-06)
```

## Arguments

- x:

  A `gsd_tbl` object.

- check_sum:

  Should retained percentages be checked within each sample?

- tolerance:

  Numeric tolerance used when checking sample totals.

## Value

Invisibly returns `x` if validation succeeds.
