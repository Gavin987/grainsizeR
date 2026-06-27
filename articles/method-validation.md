# Method Validation and Numerical Assumptions

## Purpose

This vignette documents numerical conventions used by grainsizeR and
explains how the package validates them with synthetic examples and
package example data. It is a method-audit document, not a new
scientific method.

Detailed interpretation of table layouts versus measurement workflows is
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
#> New names:
#> • `` -> `...1`
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
names describe table layout, not measurement method. Coarse
Wentworth-style gravel, sand, and mud summaries agree between the two
files because both represent the same aggregate behavior at 62.5 um.
Clay/silt-level schemes such as USDA, ISSS, and UK SSEW require
thresholds such as 2, 20, 50, 60, or 63 um; these are better resolved
when finite measured boundaries bracket those thresholds.

Instrument outputs such as laser cumulative percent-finer curves may
require preprocessing before import.
[`read_gsd()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd.md)
expects retained proportions or retained percentages by size class, not
cumulative percent passing.

## Percent-Finer Convention

grainsizeR uses cumulative percent finer. At a finite boundary, percent
finer is the retained percent below that boundary. This convention is
used by
[`gs_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/gs_cumulative.md),
[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md),
and
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md).

## D-Values

`D_p` is the grain size at which `p` percent of the sample is finer. For
example, `D50` is the median grain size by the percent-finer convention.

``` r
gs_d_values(subset(gs_long, sample_id == "WN1_upper"), probs = c(10, 50, 90), extrapolate = "warn_linear")
#> # A tibble: 3 × 7
#>   sample_id percentile grain_size_um grain_size_mm grain_size_phi
#>   <chr>          <dbl>         <dbl>         <dbl>          <dbl>
#> 1 WN1_upper         10          67.8        0.0678           3.88
#> 2 WN1_upper         50         155.         0.155            2.69
#> 3 WN1_upper         90         494.         0.494            1.02
#> # ℹ 2 more variables: interpolation_scale <chr>, extrapolated <lgl>
```

## Threshold Interpolation

[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
estimates percent finer at arbitrary thresholds by interpolating the
cumulative percent-finer curve between finite boundaries. Thresholds do
not need to be measured boundaries. This is how thresholds such as 2,
20, 50, 60, and 63 um are handled when they are bracketed by finite
class boundaries.

``` r
suppressWarnings(gs_percent_finer(
  subset(gs_long, sample_id == "WN1_upper"),
  sizes = c(20, 50, 60, 63),
  size_unit = "um",
  extrapolate = "warn_linear"
))
#> # A tibble: 4 × 8
#>   sample_id threshold_um threshold_mm threshold_phi percent_finer
#>   <chr>            <dbl>        <dbl>         <dbl>         <dbl>
#> 1 WN1_upper           20        0.02           5.64        -56.3 
#> 2 WN1_upper           50        0.05           4.32         -6.53
#> 3 WN1_upper           60        0.06           4.06          3.37
#> 4 WN1_upper           63        0.063          3.99          6.01
#> # ℹ 3 more variables: percent_coarser <dbl>, interpolation_scale <chr>,
#> #   extrapolated <lgl>
```

## Open-Ended Terminal Classes

Terminal open-ended classes are not silently treated as bounded
intervals. For example, a final class such as `<0.0625 mm` is not
treated as `[0, 62.5]`. When a requested D-value or threshold falls
inside an open-ended class, `extrapolate = "error"` reports the
unresolved value. Users can explicitly set `extrapolate = "warn_linear"`
when extrapolation is acceptable for their workflow.

[`gs_diagnostics()`](https://Gavin987.github.io/grainsizeR/reference/gs_diagnostics.md)
can be used before summary calculations to identify samples with
unresolved D-values, unresolved clay/silt thresholds, open-ended
terminal classes, or fraction schemes that require finer measurements.

``` r
gs_diagnostics(subset(gs_wide, sample_id == "WN1_upper"), output = "summary")
#> # A tibble: 1 × 8
#>   sample_id  n_ok n_warning n_error n_info has_error has_warning overall_status
#>   <chr>     <int>     <int>   <int>  <int> <lgl>     <lgl>       <chr>         
#> 1 WN1_upper    23         6       0      2 FALSE     TRUE        warning
```

## Fraction Schemes

Fraction schemes use
[`gs_percent_finer()`](https://Gavin987.github.io/grainsizeR/reference/gs_percent_finer.md)
internally at scheme boundaries. Coarse schemes such as
`wentworth_major` can be robust when their thresholds are resolved.
Texture fraction schemes with fine thresholds should use input data that
bracket those thresholds with finite boundaries, regardless of whether
the table is long or wide.

``` r
head(gs_fractions_wide(gs_long, scheme = "wentworth_major"))
#> # A tibble: 6 × 4
#>   sample_id  gravel_percent sand_percent mud_percent
#>   <chr>               <dbl>        <dbl>       <dbl>
#> 1 Cd1_deeper          2.76          89.4        7.87
#> 2 Cd1_upper           1.05          96.6        2.37
#> 3 Cd2_deeper          1.09          89.5        9.42
#> 4 Cd2_upper           0.359         98.1        1.57
#> 5 Cd3_deeper          0.365         89.9        9.75
#> 6 Cd3_upper           0.411         98.4        1.22
head(gs_fractions_wide(gs_wide, scheme = "wentworth_major"))
#> # A tibble: 6 × 4
#>   sample_id  gravel_percent sand_percent mud_percent
#>   <chr>               <dbl>        <dbl>       <dbl>
#> 1 Cd1_deeper          2.76          89.4        7.87
#> 2 Cd1_upper           1.05          96.6        2.37
#> 3 Cd2_deeper          1.09          89.5        9.42
#> 4 Cd2_upper           0.359         98.1        1.57
#> 5 Cd3_deeper          0.365         89.9        9.75
#> 6 Cd3_upper           0.411         98.4        1.22
```

## Folk and Ward Statistics

Folk and Ward statistics are calculated from boundary-interpolated
D-values. If a required D-value falls outside the finite boundary curve,
users must choose whether to error or explicitly extrapolate.

``` r
suppressWarnings(gs_folk_ward(
  subset(gs_long, sample_id == "WN1_upper"),
  extrapolate = "warn_linear"
))
#> # A tibble: 1 × 26
#>   sample_id D5_um D16_um D25_um D50_um D75_um D84_um D95_um D5_phi D16_phi
#>   <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>   <dbl>
#> 1 WN1_upper  61.8   75.7   89.4   155.   327.   419.   996.   4.02    3.72
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
  subset(gs_long, sample_id == "WN1_upper"),
  open_end = "extend_phi"
))
#> # A tibble: 1 × 14
#>   sample_id moment_method   mean_moment mean_moment_unit mean_moment_um
#>   <chr>     <chr>                 <dbl> <chr>                     <dbl>
#> 1 WN1_upper logarithmic_phi        2.47 phi                        180.
#> # ℹ 9 more variables: mean_moment_phi <dbl>, sd_moment <dbl>,
#> #   sd_moment_unit <chr>, skewness_moment <dbl>, kurtosis_moment <dbl>,
#> #   retained_percent_used <dbl>, open_end <chr>, open_end_estimated <lgl>,
#> #   open_end_omitted <lgl>
```

## Summary-Table Consistency

[`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md)
is a reporting convenience wrapper around lower-level functions. It does
not introduce new calculations; tests compare its output against
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md),
[`gs_grain_size_indices()`](https://Gavin987.github.io/grainsizeR/reference/gs_grain_size_indices.md),
[`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
and
[`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

``` r
sample_id <- "WN1_upper"
summary <- suppressWarnings(gs_parameters(
  subset(gs_long, sample_id == sample_id),
  parameters = c("d_values", "indices", "folk_ward", "fractions"),
  fraction_scheme = "gradistat",
  extrapolate = "warn_linear"
))
summary
#> # A tibble: 44 × 41
#>    sample_id  D5_um D10_um D16_um D25_um D50_um D75_um D84_um D90_um D95_um
#>    <chr>      <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
#>  1 Cd1_deeper 59.7   64.7    71.2   82.2   123.   264.   389.   511.  1133.
#>  2 Cd1_upper  66.6   75.2    87.0  108.    175.   286.   366.   432.   496.
#>  3 Cd2_deeper 58.7   63.0    68.7   78.1   112.   215.   298.   383.   472.
#>  4 Cd2_upper  69.6   81.6    98.6  130.    251.   358.   408.   444.   477.
#>  5 Cd3_deeper 58.7   62.7    67.9   76.5   107.   210.   296.   370.   445.
#>  6 Cd3_upper  71.8   86.2   107.   142.    261.   365.   412.   447.   478.
#>  7 Cd4_deeper 60.1   63.9    68.7   76.7   104.   197.   299.   396.   509.
#>  8 Cd4_upper  66.5   77.2    92.4  121.    227.   350.   404.   444.   481.
#>  9 Nn1_deeper  4.87   9.13   15.9   46.0   104.   245.   338.   417.   497.
#> 10 Nn1_upper  63.0   69.0    77.1   91.0   151.   278.   347.   402.   455.
#> # ℹ 34 more rows
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
