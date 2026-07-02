# List built-in grain-size fraction schemes

`gs_fraction_schemes()` returns the particle-size component definitions
used by
[`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md).
Bounds are returned in millimetres and micrometres. Fraction
calculations use the millimetre bounds after normalizing `gsd_tbl` sizes
from their internal micrometre storage. Each scheme is represented as a
complete, non-overlapping particle-size partition. Lower bounds are
inclusive for interpretation, and upper bounds define the cumulative
threshold used to calculate each fraction. `gravel_sand_mud` is an
explicit public alias of `wentworth_major`; both schemes use gravel,
sand, and mud components with boundaries at 2000 and 62.5 micrometres.
GRADISTAT ternary examples use `scheme = "gravel_sand_mud"` because it
makes the required ternary components explicit, while `wentworth_major`
remains available for users who prefer the Wentworth naming.

## Usage

``` r
gs_fraction_schemes()
```

## Value

A tibble describing built-in fraction schemes.
