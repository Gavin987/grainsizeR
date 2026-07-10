# List built-in grain-size fraction schemes

`gs_fraction_schemes()` returns the particle-size component definitions
used by
[`gs_fractions()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions.md).
Bounds are returned in millimetres and micrometres. Fraction
calculations use the millimetre bounds after normalizing `gsd_tbl` sizes
from their internal micrometre storage. Each scheme is represented as a
complete, non-overlapping particle-size partition. Lower bounds are
inclusive for interpretation, and upper bounds define the cumulative
threshold used to calculate each fraction. `gravel_sand_mud` is an
independent GRADISTAT-compatible gravel/sand/mud scheme with boundaries
at 2000 and 63 micrometres. `wentworth_major` is a strict Wentworth /
phi-scale major scheme with boundaries at 2000 and 62.5 micrometres, so
`gravel_sand_mud` and `wentworth_major` are not guaranteed to produce
identical output.

## Usage

``` r
gs_fraction_schemes()
```

## Value

A tibble describing built-in fraction schemes.
