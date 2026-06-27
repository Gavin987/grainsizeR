# Convert ternary coordinates to Cartesian coordinates

`ternary_to_xy()` converts left, right, and top ternary percentages to
Cartesian coordinates for an equilateral triangle. The transformation
uses public-domain triangle geometry and does not depend on external
texture classification data.

## Usage

``` r
ternary_to_xy(left, right, top, normalize = TRUE)
```

## Arguments

- left:

  Numeric vector for the left-axis component.

- right:

  Numeric vector for the right-axis component.

- top:

  Numeric vector for the top-axis component.

- normalize:

  Should rows be normalized so `left + right + top = 100`?

## Value

A tibble with Cartesian coordinates and normalized ternary values.
