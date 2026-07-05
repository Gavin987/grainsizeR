# Plot a GRADISTAT-inspired grain-size summary

`plot_gradistat_summary()` creates an original, report-oriented sediment
grain-size diagnostic plot for one sample. It combines retained
distribution bars, a cumulative percent-finer curve, optional D-value
markers, optional fraction boundaries, and a compact caption of summary
statistics.

## Usage

``` r
plot_gradistat_summary(
  x,
  sample_id = NULL,
  x_scale = c("phi", "log10", "linear_um"),
  fraction_scheme = "gradistat",
  d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
  show_distribution = TRUE,
  show_cumulative = TRUE,
  show_d_values = TRUE,
  show_fraction_bands = TRUE,
  show_summary = TRUE,
  interpolation_scale = "phi",
  extrapolate = "error",
  moments_open_end = "error"
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- sample_id:

  Sample identifier. Required when `x` contains multiple samples.

- x_scale:

  Display scale for the grain-size axis. `"phi"` uses phi units with
  coarser sizes on the left and finer sizes on the right. `"log10"` uses
  a log10 micrometer axis. `"linear_um"` uses a linear micrometer axis.

- fraction_scheme:

  Built-in fraction scheme used for fraction boundaries and summary
  percentages.

- d_values:

  Numeric vector of D-value percentiles to mark. Marked D-values falling
  on a plateau caused by consecutive zero-retained classes are placed
  using
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)'s
  deterministic tie-breaking rule (see its documentation).

- show_distribution:

  Should retained distribution bars be drawn?

- show_cumulative:

  Should the cumulative percent-finer curve be drawn?

- show_d_values:

  Should selected D-values be marked when resolvable?

- show_fraction_bands:

  Should fraction boundary markers be drawn?

- show_summary:

  Should a summary caption be added?

- interpolation_scale:

  Interpolation scale passed to D-value, fraction, Folk and Ward, and
  index calculations.

- extrapolate:

  Extrapolation behavior passed to summary calculations. The default
  `"error"` avoids silent extrapolation into open-ended terminal
  classes. Use `"warn_linear"` explicitly when extrapolated summaries
  are acceptable.

- moments_open_end:

  Reserved for consistency with grain-size reporting workflows. Moment
  statistics are not displayed by this plot.

## Value

A `ggplot` object.

## Details

The function is inspired by common sediment grain-size reporting needs
and by the type of summary output often associated with GRADISTAT
workflows. It is not GRADISTAT software, does not reproduce the
GRADISTAT workbook layout, and does not copy GRADISTAT code, tables,
data, or plot templates.
