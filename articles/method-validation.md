# Method Validation and Numerical Assumptions

## Purpose

This vignette documents numerical conventions used by grainsizeR and
explains how the package validates them with synthetic examples and
package example data. It is a method-audit document, not a new
scientific method.

Detailed interpretation of table layouts versus measurement setups is
covered in the table layouts and measurement workflows vignette.

``` r
library(grainsizeR)
```

## Example Data Used for Validation

The package includes two example files:

``` r
long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")

gs_long <- read_gsd(
  long_file,
  format = "long",
  sample_col = "sample",
  size_col = "size",
  value_col = "proportion",
  size_unit = "mm",
  value_type = "proportion"
)

gs_wide <- read_gsd(
  wide_file,
  format = "wide",
  size_col = 1,
  size_unit = "mm",
  value_type = "percent"
)
```

`grain.long.csv` is a sieve + hydrometer example stored as a tidy long
table and has finer particle-size resolution where hydrometer data were
added. `grain.wide.csv` is a dry-sieve example stored as a multi-sample
wide table and is useful for coarse gravel/sand/mud summaries.

## Input-Bin Convention

Input rows describe retained material in grain-size classes. A numeric
label is used as a class boundary. Terminal coarse and fine classes can
be open-ended. Open-ended classes are retained in the data structure,
but their missing boundary is not silently replaced by zero or infinity
for interpolation.

## Long Versus Wide Example Data

The long and wide examples contain the same sample IDs. Here, the file
names describe table layout, not measurement method. Strict Wentworth
major summaries use the phi-scale 62.5 um sand/mud boundary. The
`gravel_sand_mud` scheme uses the GRADISTAT-compatible 63 um boundary,
so it is not guaranteed to match `wentworth_major` exactly for samples
with material near that boundary. Clay/silt-level schemes such as USDA,
ISSS, and UK SSEW require thresholds such as 2, 20, 50, 60, or 63 um;
these are better resolved when finite measured boundaries bracket those
thresholds.

Instrument outputs such as laser cumulative percent-finer curves may
require preprocessing before import.
[`read_gsd()`](https://gavin987.github.io/grainsizeR/reference/read_gsd.md)
expects retained proportions or retained percentages by size class, not
cumulative percent passing.

## Percent-Finer Convention

grainsizeR uses cumulative percent finer. At a finite boundary, percent
finer is the retained percent below that boundary. This convention is
used by
[`gs_cumulative()`](https://gavin987.github.io/grainsizeR/reference/gs_cumulative.md),
[`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md),
and
[`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md).

## D-Values

`D_p` is the grain size at which `p` percent of the sample is finer. For
example, `D50` is the median grain size by the percent-finer convention.

``` r
gs_d_values(subset(gs_long, sample_id == "S01"), probs = c(10, 50, 90), extrapolate = "warn_linear")
#> # A tibble: 3 × 7
#>   sample_id percentile grain_size_um grain_size_mm grain_size_phi
#>   <chr>          <dbl>         <dbl>         <dbl>          <dbl>
#> 1 S01               10          40.9        0.0409           4.61
#> 2 S01               50         123.         0.123            3.02
#> 3 S01               90         390.         0.390            1.36
#> # ℹ 2 more variables: interpolation_scale <chr>, extrapolated <lgl>
```

## Threshold Interpolation

[`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
estimates percent finer at arbitrary thresholds by interpolating the
cumulative percent-finer curve between finite boundaries. Thresholds do
not need to be measured boundaries. This is how thresholds such as 2,
20, 50, 60, and 63 um are handled when they are bracketed by finite
class boundaries.

``` r
suppressWarnings(gs_percent_finer(
  subset(gs_long, sample_id == "S01"),
  sizes = c(20, 50, 60, 63),
  size_unit = "um",
  extrapolate = "warn_linear"
))
#> # A tibble: 4 × 8
#>   sample_id threshold_um threshold_mm threshold_phi percent_finer
#>   <chr>            <dbl>        <dbl>         <dbl>         <dbl>
#> 1 S01                 20        0.02           5.64          3.90
#> 2 S01                 50        0.05           4.32         12.5 
#> 3 S01                 60        0.06           4.06         14.0 
#> 4 S01                 63        0.063          3.99         14.4 
#> # ℹ 3 more variables: percent_coarser <dbl>, interpolation_scale <chr>,
#> #   extrapolated <lgl>
```

## Open-Ended Terminal Classes

Terminal open-ended classes are not silently treated as bounded
intervals. For example, a final class such as `<0.0625 mm` in a strict
Wentworth-style input is not treated as `[0, 62.5]`. When a requested
D-value or threshold falls inside an open-ended class,
`extrapolate = "error"` reports the unresolved value. Users can
explicitly set `extrapolate = "warn_linear"` when extrapolation is
acceptable for their workflow.

[`gs_diagnostics()`](https://gavin987.github.io/grainsizeR/reference/gs_diagnostics.md)
can be used before summary calculations to identify samples with
unresolved D-values, unresolved clay/silt thresholds, open-ended
terminal classes, or fraction schemes that require finer measurements.

``` r
gs_diagnostics(subset(gs_wide, sample_id == "S01"), output = "summary")
#> # A tibble: 1 × 8
#>   sample_id  n_ok n_warning n_error n_info has_error has_warning overall_status
#>   <chr>     <int>     <int>   <int>  <int> <lgl>     <lgl>       <chr>         
#> 1 S01          16        12       0      3 FALSE     TRUE        warning
```

## Fraction Schemes

Fraction schemes use
[`gs_percent_finer()`](https://gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
internally at scheme boundaries. Coarse schemes such as
`wentworth_major` can be robust when their thresholds are resolved.
Texture fraction schemes with fine thresholds should use input data that
bracket those thresholds with finite boundaries, regardless of whether
the table is long or wide.

``` r
head(gs_fractions_wide(gs_long, scheme = "wentworth_major"))
#> # A tibble: 6 × 4
#>   sample_id gravel_percent sand_percent mud_percent
#>   <chr>              <dbl>        <dbl>       <dbl>
#> 1 S01                0.624         85.1      14.3  
#> 2 S02                0.224         97.8       1.93 
#> 3 S03                0.312         95.1       4.60 
#> 4 S04                0.153         89.7      10.2  
#> 5 S05                0.295         89.4      10.4  
#> 6 S06                0.230         98.8       0.964
head(gs_fractions_wide(gs_wide, scheme = "wentworth_major"))
#> # A tibble: 6 × 4
#>   sample_id gravel_percent sand_percent mud_percent
#>   <chr>              <dbl>        <dbl>       <dbl>
#> 1 S01                0.624         85.0      14.4  
#> 2 S02                0.224         97.8       1.93 
#> 3 S03                0.312         95.1       4.60 
#> 4 S04                0.153         89.6      10.2  
#> 5 S05                0.295         88.8      10.9  
#> 6 S06                0.230         98.8       0.964
```

## Folk and Ward Statistics

Folk and Ward statistics are calculated from boundary-interpolated
D-values. If a required D-value falls outside the finite boundary curve,
users must choose whether to error or explicitly extrapolate.

``` r
suppressWarnings(gs_folk_ward(
  subset(gs_long, sample_id == "S01"),
  extrapolate = "warn_linear"
))
#> # A tibble: 1 × 26
#>   sample_id D5_um D16_um D25_um D50_um D75_um D84_um D95_um D5_phi D16_phi
#>   <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>   <dbl>
#> 1 S01        25.1   64.9   76.9   123.   233.   314.   468.   5.31    3.94
#> # ℹ 16 more variables: D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>,
#> #   D84_phi <dbl>, D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>,
#> #   sorting_fw_phi <dbl>, skewness_fw <dbl>, kurtosis_fw <dbl>,
#> #   interpolation_scale <chr>, any_extrapolated <lgl>, mean_size_class <chr>,
#> #   sorting_class <chr>, skewness_class <chr>, kurtosis_class <chr>
```

## Moment Statistics

Moment statistics require explicit open-end handling.
`open_end = "error"` prevents silent assumptions.
`open_end = "extend_phi"` estimates open-ended midpoints by extending
adjacent phi intervals, and `open_end = "omit"` omits open-ended
retained classes.

``` r
suppressWarnings(gs_moments(
  subset(gs_long, sample_id == "S01"),
  open_end = "extend_phi"
))
#> # A tibble: 1 × 14
#>   sample_id moment_method   mean_moment mean_moment_unit mean_moment_um
#>   <chr>     <chr>                 <dbl> <chr>                     <dbl>
#> 1 S01       logarithmic_phi        2.97 phi                        127.
#> # ℹ 9 more variables: mean_moment_phi <dbl>, sd_moment <dbl>,
#> #   sd_moment_unit <chr>, skewness_moment <dbl>, kurtosis_moment <dbl>,
#> #   retained_percent_used <dbl>, open_end <chr>, open_end_estimated <lgl>,
#> #   open_end_omitted <lgl>
```

## Summary-Table Consistency

[`gs_parameters()`](https://gavin987.github.io/grainsizeR/reference/gs_parameters.md)
is a reporting convenience wrapper around lower-level functions. It does
not introduce new calculations; tests compare its output against
[`gs_d_values()`](https://gavin987.github.io/grainsizeR/reference/gs_d_values.md),
[`gs_grain_size_indices()`](https://gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
[`gs_folk_ward()`](https://gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
and
[`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

``` r
sample_id <- "S01"
summary <- suppressWarnings(gs_parameters(
  subset(gs_long, sample_id == sample_id),
  parameters = c("d_values", "indices", "folk_ward", "fractions"),
  fraction_scheme = "gradistat",
  extrapolate = "warn_linear"
))
summary
#> # A tibble: 30 × 41
#>    sample_id D5_um D10_um D16_um D25_um D50_um D75_um D84_um D90_um D95_um
#>    <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
#>  1 S01        25.1   40.9   64.9   76.9   123.   233.   314.   390.   468.
#>  2 S02        68.2   77.6   90.7  114.    175.   267.   346.   412.   476.
#>  3 S03        63.5   69.5   77.5   91.3   151.   278.   347.   402.   455.
#>  4 S04        32.3   60.2   69.6   81.2   125.   258.   333.   395.   456.
#>  5 S05        35.3   62.2   68.7   80.1   123.   270.   347.   410.   472.
#>  6 S06        68.5   76.1   86.2  104.    216.   346.   399.   439.   475.
#>  7 S07        67.1   75.6   87.3  108.    175.   286.   366.   432.   496.
#>  8 S08        70.1   82.0   98.8  130.    251.   358.   408.   444.   477.
#>  9 S09        72.2   86.6  108.   142.    261.   365.   412.   447.   478.
#> 10 S10        67.0   77.6   92.7  121.    227.   350.   404.   444.   481.
#> # ℹ 20 more rows
#> # ℹ 31 more variables: D30_um <dbl>, D60_um <dbl>, Cu <dbl>, Cc <dbl>,
#> #   So_trask <dbl>, Sk_trask <dbl>, fine_content_percent <dbl>,
#> #   fine_threshold_um <dbl>, fine_equivalent <dbl>, interpolation_scale <chr>,
#> #   D5_phi <dbl>, D16_phi <dbl>, D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>,
#> #   D84_phi <dbl>, D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>,
#> #   sorting_fw_phi <dbl>, skewness_fw <dbl>, kurtosis_fw <dbl>, …
```

## What This Package Does Not Do

grainsizeR does not implement civil-engineering classification systems.
Built-in official texture polygon datasets are not bundled yet.
User-supplied texture polygons are supported, and source-audit scaffolds
document how future official polygon datasets should be reconstructed
and reviewed.
