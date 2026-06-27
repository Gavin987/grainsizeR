# Calculate grain-size moment statistics

`gs_moments()` calculates population-style moments from grain-size class
midpoints. Logarithmic moments use phi midpoint values, while arithmetic
moments use micrometer midpoint values.

## Usage

``` r
gs_moments(
  x,
  method = c("logarithmic_phi", "arithmetic_um"),
  open_end = c("error", "extend_phi", "omit")
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- method:

  Moment scale. `"logarithmic_phi"` uses phi midpoints, and
  `"arithmetic_um"` uses micrometer midpoints.

- open_end:

  Handling for open-ended classes. `"error"` stops when open-ended
  classes contain retained material, `"extend_phi"` estimates open-ended
  midpoints by extending adjacent intervals in phi space, and `"omit"`
  drops open-ended classes and renormalizes the remaining retained
  percentages.

## Value

A tibble with one row per sample and moment statistics.
