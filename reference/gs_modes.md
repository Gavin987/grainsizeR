# Identify modal grain-size classes

`gs_modes()` reports the largest retained grain-size classes in each
sample. The output is intended for GRADISTAT-style summaries that list
primary, secondary, and tertiary modes. Modes are ranked by retained
class percentage, with deterministic tie ordering by the original
coarse-to-fine class order.

## Usage

``` r
gs_modes(x, n_modes = 3)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- n_modes:

  Number of modal classes to return per sample.

## Value

A tibble with exactly `n_modes` rows per sample and modal class
descriptors. Samples with fewer observed modal classes are padded with
`NA` descriptor fields and `mode_status = "unresolved"`.

## Details

The reported mode is a modal class midpoint, not a true continuous
density mode. Open-ended terminal classes do not have reliable
midpoints; if an open-ended class is selected, midpoint fields are `NA`
and `mode_status` is `"open_interval"`. Tied retained percentages are
marked with `mode_status = "tied"`. The `sample_modality` column is an
operational descriptor based on retained class frequencies, not a formal
mixture model.

## Examples

``` r
gsd <- as_gsd_tbl(
  data.frame(
    sample = rep("A", 5),
    size_mm = c(2, 1, 0.5, 0.25, 0.125),
    retained = c(5, 35, 15, 30, 15)
  ),
  sample,
  size_mm,
  retained,
  value_type = "percent"
)

gs_modes(gsd)
#> # A tibble: 3 × 12
#>   sample_id sample_modality mode_rank mode_size_mm mode_size_um mode_phi
#>   <chr>     <chr>               <int>        <dbl>        <dbl>    <dbl>
#> 1 A         bimodal                 1        1.41         1414.     -0.5
#> 2 A         bimodal                 2        0.354         354.      1.5
#> 3 A         bimodal                 3        0.707         707.      0.5
#> # ℹ 6 more variables: mode_class_lower_mm <dbl>, mode_class_upper_mm <dbl>,
#> #   mode_percent <dbl>, mode_class_label <chr>, is_open_interval <lgl>,
#> #   mode_status <chr>
```
