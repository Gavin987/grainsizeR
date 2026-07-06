# Calculate grain-size fraction percentages

`gs_fractions()` calculates sediment or soil fraction percentages using
a named built-in particle-size scheme. Schemes are treated as complete,
non-overlapping particle-size partitions. Fractions are calculated from
cumulative percent-finer values at scheme thresholds by calling
[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
for thresholds inside the observed finite size range.

## Usage

``` r
gs_fractions(
  x,
  scheme = "wentworth_major",
  normalize = c("none", "fine_earth"),
  interpolation_scale = "phi",
  unresolved = c("warn_na", "error"),
  extrapolate = "error"
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- scheme:

  Built-in fraction scheme name.

- normalize:

  Normalization mode. `"none"` returns whole-sample percentages.
  `"fine_earth"` requires a scheme with a `gravel` component, excludes
  gravel rows, and normalizes the remaining non-gravel fractions against
  the non-gravel total.

- interpolation_scale:

  Interpolation scale passed to
  [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).

- unresolved:

  Behavior when required thresholds cannot be calculated. `"warn_na"`
  warns and returns `NA` for affected components. `"error"` throws an
  error.

- extrapolate:

  Extrapolation behavior passed to
  [`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md).
  The default `"error"` avoids silent extrapolation into open-ended
  terminal classes.

## Value

A tibble with one row per sample and scheme component.

## Details

Scheme thresholds do not need to match observed grain-size boundaries.
When thresholds such as 0.002, 0.020, 0.050, 0.060, or 0.063 mm are
bracketed by finite class boundaries, percent-finer values are
interpolated on the cumulative curve. Fraction and texture functions
automatically use the normalized particle-size scale from `gsd_tbl`;
users do not need to specify millimetres or micrometres after import.
Thresholds above the largest observed finite boundary resolve to 100
percent finer. Thresholds below the smallest observed finite boundary
resolve to 0 percent finer **only when the excluded open-lower (pan)
class carries no retained mass** - in that case there is genuinely
nothing finer than the threshold, and 0 percent is exact, not an
assumption. When the pan class does carry retained mass, the true value
below the smallest observed boundary is not derivable from the data, and
this now follows the same `extrapolate` policy
[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
uses for the identical situation: `extrapolate = "error"` (the default)
throws, and `extrapolate = "warn_linear"` resolves a
linearly-extrapolated value with a warning. Earlier versions of this
function returned a confident 0 percent unconditionally in this case
regardless of pan mass - this was a silent-assumption gap, corrected in
this version (see `dev-notes/AUDIT_LOG.md`'s "Root-cause: gs_fractions()
below-finest- boundary behavior" entry for the full investigation this
fix implements). `NA` is reserved for thresholds that are genuinely
unresolved inside the finite observed size range (governed by
`unresolved`, separately from `extrapolate`). Fraction schemes do not
extrapolate unless `extrapolate = "warn_linear"` is passed explicitly.

Before applying the above range logic, a requested threshold is first
checked against a small, explicit table of known nominal sieve-mesh
equivalences (see `nominal_sieve_equivalence_groups_mm()`) - currently
one group, `{0.0625, 0.063}` mm, reflecting that no sieve manufacturer
cuts a 0.0625 mm (1/16 mm, the Udden-Wentworth phi-scale theoretical
boundary used by `wentworth_major`/`wentworth_detailed`) mesh: sieves
certified near this size under ISO 3310-1, ASTM E11, or DIN 4188 are
labelled 0.063 mm (the value `gravel_sand_mud`/`gradistat`/`germany_63`
use). If a sample's own finite boundary is a nominal-equivalence match
for the requested threshold, the threshold resolves directly from that
boundary's real value - not as an extrapolation, and not via the
pan-mass logic above. This equivalence match only rescues thresholds
that would otherwise be unresolved/extrapolated; when a threshold is
already resolvable by real interpolation between two distinct measured
boundaries (e.g. a sample with genuine finer-than-63μm data), real
interpolated data governs and the equivalence table has no effect. Only
the one listed group is ever treated as equivalent - unrelated
boundaries (e.g. USDA's 0.05 mm) are never affected.

Fraction thresholds interpolate using
[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)'s
size-as-`x` direction, so the tied-cumulative-value scenario that
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
resolves deterministically (see its documentation) cannot occur here.
