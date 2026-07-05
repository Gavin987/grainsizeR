# Summarize grain-size parameters

`gs_parameters()` is a minimal user-facing summary interface for
selected D-values returned by
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md),
additional grain-size indices returned by
[`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
GRADISTAT-style D-spread descriptors returned by
[`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md),
Folk and Ward graphical statistics returned by
[`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
midpoint moment statistics returned by
[`gs_moments()`](https://Gavin987.github.io/grainsizeR/reference/gs_moments.md),
modal class descriptors returned by
[`gs_modes()`](https://Gavin987.github.io/grainsizeR/reference/gs_modes.md),
and particle-size fractions returned by
[`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).
Optional descriptor and quality groups add GRADISTAT-style printout
terms and advisory quality flags.

## Usage

``` r
gs_parameters(
  x,
  parameters = c("D10", "D30", "D50", "D60", "D75", "indices"),
  output = c("wide", "long"),
  d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
  interpolation_scale = "phi",
  extrapolate = "error",
  d_spread_scale = "um",
  fine_threshold_um = 62.5,
  moments_method = "logarithmic_phi",
  moments_open_end = "error",
  n_modes = 3,
  sediment_loss_percent = NULL,
  sediment_loss_warning_percent = 2,
  fine_pan_info_percent = 1,
  fine_pan_warning_percent = 5,
  fraction_scheme = "wentworth_major",
  fraction_normalize = "none",
  fraction_unresolved = "warn_na"
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- parameters:

  Character vector of parameters. Supported values are `"d_values"`,
  D-value tokens such as `"D10"`, `"D30"`, and `"D90"`, plus the aliases
  `"d_spread"`, `"indices"`, `"folk_ward"`, `"moments"`, `"modes"`,
  `"descriptors"`, `"quality"`, and `"fractions"`. `"engineering"` is
  accepted as a compatibility alias for `"indices"`.

- output:

  Output shape. `"wide"` returns one row per sample, while `"long"`
  returns parameter-value rows.

- d_values:

  Numeric vector of D-value percentiles used when `parameters` includes
  `"d_values"`.

- interpolation_scale:

  Interpolation scale passed to lower-level calculations.

- extrapolate:

  Extrapolation behavior passed to lower-level calculations.

- d_spread_scale:

  Metric reporting scale passed to
  [`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md).

- fine_threshold_um:

  Fine-content threshold in micrometers for grain-size index summaries.

- moments_method:

  Moment scale passed to
  [`gs_moments()`](https://Gavin987.github.io/grainsizeR/reference/gs_moments.md).

- moments_open_end:

  Open-ended class handling passed to
  [`gs_moments()`](https://Gavin987.github.io/grainsizeR/reference/gs_moments.md).

- n_modes:

  Number of modal classes passed to
  [`gs_modes()`](https://Gavin987.github.io/grainsizeR/reference/gs_modes.md)
  when `parameters` includes `"modes"`.

- sediment_loss_percent:

  Optional sediment-loss percentages passed to
  [`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md)
  when `parameters` includes `"quality"`.

- sediment_loss_warning_percent:

  Advisory sediment-loss threshold passed to
  [`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md).

- fine_pan_info_percent:

  Advisory fine-pan information threshold passed to
  [`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md).

- fine_pan_warning_percent:

  Advisory fine-pan warning threshold passed to
  [`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md).

- fraction_scheme:

  Fraction scheme passed to
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- fraction_normalize:

  Normalization mode passed to
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- fraction_unresolved:

  Unresolved-threshold behavior passed to
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

## Value

A tibble containing requested grain-size parameters.

## Details

The function is useful for generating compact summary tables for
reports. It returns ordinary tabular output, so file export is
intentionally left to standard R workflows such as
[`write.csv()`](https://rdrr.io/r/utils/write.table.html) or
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

Any D-value tokens are ultimately computed by
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md),
including its deterministic tie-breaking rule for percentiles that fall
on a plateau caused by consecutive zero-retained classes (see
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
for details).
