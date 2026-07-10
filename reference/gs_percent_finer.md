# Calculate percent finer than grain-size thresholds

`gs_percent_finer()` returns the cumulative percent finer than one or
more requested grain-size thresholds for each sample. Values are taken
exactly from finite boundaries when thresholds match them, otherwise
they are interpolated between finite class boundaries on the selected
scale. This is the function used by grainsizeR to estimate percent finer
at arbitrary particle-size thresholds such as 2, 20, 50, 60, and 63 um;
requested thresholds do not need to match measured class boundaries.

## Usage

``` r
gs_percent_finer(
  x,
  sizes,
  size_unit = "um",
  interpolation_scale = c("phi", "log_um", "linear_um"),
  extrapolate = c("error", "warn_linear"),
  scale = NULL
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- sizes:

  Numeric vector of grain-size thresholds.

- size_unit:

  Unit for `sizes`. Supported values are `"um"`, `"mm"`, and `"phi"`.

- interpolation_scale:

  Interpolation scale. `"phi"` interpolates in phi units, `"log_um"`
  interpolates in log10 micrometers, and `"linear_um"` interpolates
  directly in micrometers.

- extrapolate:

  Behavior when a requested threshold falls outside the observed finite
  boundary size range, including thresholds inside open-ended terminal
  classes. `"error"` throws an error, and `"warn_linear"` warns,
  linearly extrapolates on the selected scale, and marks affected rows
  with `extrapolated = TRUE`.

- scale:

  Compatibility alias for `interpolation_scale`.

## Value

A tibble with one row per sample and requested threshold.

## Details

Interpolation is based on
[`gs_cumulative()`](https://gavin987.github.io/grainsizeR/reference/gs_cumulative.md).
Terminal open-ended fine or coarse classes are not silently treated as
bounded intervals. Thresholds that fall inside an open-ended terminal
class are unresolved with `extrapolate = "error"` and are linearly
extrapolated with a warning only when `extrapolate = "warn_linear"`.

Before that range check, a requested threshold is first checked against
a small, explicit table of known nominal sieve-mesh equivalences (see
`nominal_sieve_equivalence_groups_mm()`) - currently one group,
`{0.0625, 0.063}` mm, reflecting that no sieve manufacturer cuts a
0.0625 mm (1/16 mm, the Udden-Wentworth phi-scale theoretical boundary)
mesh: sieves certified near this size under ISO 3310-1, ASTM E11, or DIN
4188 are labelled 0.063 mm. If a sample's own finite boundary is a
nominal-equivalence match for a requested threshold that would otherwise
fall outside the observed range, that threshold resolves directly from
the matched boundary's real value (`extrapolated = FALSE`), not as an
extrapolation. This only rescues thresholds that would otherwise be
unresolved: when a threshold already falls inside the observed range,
real interpolation governs and the equivalence table has no effect. Only
the one listed group is ever treated as equivalent - unrelated
boundaries (e.g. USDA's 0.05 mm) are never affected.

Unlike
[`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md),
`gs_percent_finer()` interpolates using requested size thresholds as the
independent variable, and finite class boundaries are always distinct
sizes - so the tied-cumulative-value scenario that
[`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md)
resolves deterministically (see its documentation) cannot occur here.
