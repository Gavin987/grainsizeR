# Plot grain-size fraction composition

`plot_fractions()` plots fraction percentages from
[`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md)
as stacked bars with one bar per sample. Fraction components use the
normalized particle-size scale from `gsd_tbl`; users do not need to
specify size units for plotting after import.

## Usage

``` r
plot_fractions(
  x,
  scheme = "wentworth_major",
  normalize = "none",
  sample = NULL,
  sample_id = NULL,
  fill_palette = c("default", "YlOrBr", "none"),
  na_to_zero = FALSE
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- scheme:

  Built-in fraction scheme name passed to
  [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md).

- normalize:

  Normalization mode passed to
  [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md).

- sample:

  Optional sample selector. A character value selects by sample ID; a
  numeric value selects by one-based sample index using the order in
  which samples appear in `x`.

- sample_id:

  Optional character vector of sample identifiers to include. Kept for
  backward compatibility; use `sample` for new code.

- fill_palette:

  Fill palette. `"default"` uses ggplot2 defaults, `"YlOrBr"` uses
  [`grDevices::hcl.colors()`](https://rdrr.io/r/grDevices/palettes.html)
  with a yellow-orange-brown sequence, and `"none"` leaves the scale
  unchanged.

- na_to_zero:

  Should unresolved fraction percentages be plotted as zero? The default
  `FALSE` preserves `NA` values returned by
  [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md).
  Use `TRUE` to draw stacked bars without dropping components whose
  thresholds could not be resolved from the available grain-size
  classes. This affects only the plotted data and does not change the
  underlying
  [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md)
  calculation.

## Value

A `ggplot` object.

## Examples

``` r
x <- data.frame(
  sample_id = c("A", "A", "A", "A", "B", "B", "B", "B"),
  size_mm = rep(c(2, 0.5, 0.063, 0.001), 2),
  retained_proportion = c(0.20, 0.50, 0.30, 0, 0.10, 0.60, 0.30, 0)
)
gsd <- as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
plot_fractions(gsd, scheme = "wentworth_major")

plot_fractions(gsd, sample = 1, scheme = "wentworth_major")

plot_fractions(gsd, scheme = "gravel_sand_mud", fill_palette = "YlOrBr")
```
