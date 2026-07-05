# Diagnose grain-size data quality and resolvability

`gs_diagnostics()` reports data-quality and computational-resolvability
checks for a `gsd_tbl`. It is designed to be run before D-values,
percent-finer thresholds, fraction schemes, summary tables, or texture
workflows.

## Usage

``` r
gs_diagnostics(
  x,
  d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
  thresholds_um = c(2, 20, 50, 60, 62.5, 63, 2000),
  fraction_schemes = c("wentworth_major", "gradistat", "usda", "isss", "uk_ssew"),
  retained_tolerance = 1e-06,
  fine_boundary_um = 63,
  hydrometer_trigger_percent = 10,
  extrapolate = c("error", "warn_linear"),
  output = c("long", "wide", "summary")
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- d_values:

  Numeric D-value percentiles to check. Resolvability is determined via
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md),
  including its deterministic tie-breaking rule for percentiles that
  fall on a plateau caused by consecutive zero-retained classes (see
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
  for details).

- thresholds_um:

  Numeric grain-size thresholds, in micrometers, to check with the
  package percent-finer convention.

- fraction_schemes:

  Built-in fraction schemes to check for threshold resolvability.

- retained_tolerance:

  Tolerance for retained percentages summing to 100.

- fine_boundary_um:

  Boundary used for fine-resolution and hydrometer workflow diagnostics.

- hydrometer_trigger_percent:

  Workflow trigger for the percent finer than `fine_boundary_um`.

- extrapolate:

  Extrapolation behavior passed to lower-level resolvability checks. The
  default `"error"` reports open-tail limitations instead of
  extrapolating.

- output:

  Output shape. `"long"` returns one row per sample and check.
  `"summary"` returns counts by sample. `"wide"` returns compact status
  columns by sample.

## Value

A tibble of diagnostics.

## Details

Diagnostics are not a replacement for domain judgment. The hydrometer
trigger check is a workflow diagnostic, not a universal scientific rule.
Open-ended terminal bins are reported explicitly and are not silently
treated as bounded intervals.
