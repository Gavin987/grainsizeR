# Calculate GRADISTAT-style D-spread descriptors

`gs_d_spread()` calculates D-value spread descriptors commonly reported
in GRADISTAT-style grain-size summaries. It reuses
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
for D10, D25, D50, D75, and D90, then derives D90/D10, D90 - D10,
D75/D25, D75 - D25, and the Krumbein (1938) quartile deviation.

## Usage

``` r
gs_d_spread(
  x,
  scale = c("um", "mm"),
  interpolation_scale = c("phi", "log_um", "linear_um"),
  extrapolate = c("error", "warn_linear")
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- scale:

  Metric reporting scale for D-values and differences. Supported values
  are `"um"` and `"mm"`.

- interpolation_scale:

  Interpolation scale passed to
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md).

- extrapolate:

  Extrapolation behavior passed to
  [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md).

## Value

A tibble with one row per sample and D-spread descriptor columns,
including `quartile_deviation_phi` (Krumbein, 1938).

## Details

Ratios and differences are metric descriptors. `scale = "um"` reports
D-values and differences in micrometers, while `scale = "mm"` reports
them in millimeters. `scale = "phi"` is not supported because phi
differences are not the same parameter as metric D-value spread
differences. Optional log ratio columns are calculated from positive
metric D-values.

`quartile_deviation_phi` is the Krumbein (1938) quartile deviation, Qd =
(D25_phi - D75_phi) / 2, reported in phi units regardless of `scale`
(Krumbein's original measure is a phi-scale transform of Trask's (1932)
metric quartile ratio, the same lineage as `So_trask` in
[`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md)).
It is always positive under the package's D-value convention, where
`D_p` is the grain size at which `p` percent of the sample is finer,
because D25 is a larger phi value (finer material) than D75.

Open-tail behavior follows
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md):
by default unresolved requested percentiles throw an error, and
`extrapolate = "warn_linear"` explicitly allows linear extrapolation and
marks affected samples with `any_extrapolated = TRUE`. D-values falling
on a tied cumulative plateau (from consecutive zero-retained classes)
are also resolved via
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)'s
deterministic tie-breaking rule.

## Examples

``` r
gsd <- as_gsd_tbl(
  data.frame(
    sample = rep("A", 5),
    size_mm = c(2, 1, 0.5, 0.25, 0.125),
    retained = c(5, 15, 35, 30, 15)
  ),
  sample,
  size_mm,
  retained,
  value_type = "percent"
)

gs_d_spread(gsd, extrapolate = "warn_linear")
#> Warning: Requested percentiles for sample `A` fall outside the finite boundary curve range; linearly extrapolating.
#> # A tibble: 1 × 15
#>   sample_id   D10   D25   D50   D75   D90 d_value_unit D90_D10_ratio
#>   <chr>     <dbl> <dbl> <dbl> <dbl> <dbl> <chr>                <dbl>
#> 1 A          223.  315.  552.  906. 1587. um                    7.13
#> # ℹ 7 more variables: D90_minus_D10 <dbl>, D75_D25_ratio <dbl>,
#> #   D75_minus_D25 <dbl>, D90_D10_log_ratio <dbl>, D75_D25_log_ratio <dbl>,
#> #   quartile_deviation_phi <dbl>, any_extrapolated <lgl>
```
