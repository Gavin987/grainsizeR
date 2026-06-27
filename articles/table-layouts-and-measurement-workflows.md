# Table layouts and measurement workflows

## Purpose

This vignette separates three concepts that are easy to mix up:

1.  Measurement workflow, such as dry sieve, sieve + hydrometer,
    pipette, laser diffraction, or another particle-size workflow.
2.  Table layout, such as a single-sample table, a multi-sample wide
    table, or a tidy long table.
3.  Data type, such as retained percent by class, cumulative percent
    finer, frequency or density output, raw counts, or
    instrument-specific output.

grainsizeR currently reads retained proportions or retained percentages
by size class. It does not infer laboratory method from file shape
alone.

``` r
library(grainsizeR)
```

## Table Layout Is Not Measurement Method

`format = "long"` and `format = "wide"` describe how the file is
arranged. They do not identify the laboratory or instrument method. A
wide table can represent dry-sieve, hydrometer, pipette,
laser-diffraction, or other particle-size data. A long table can also
represent any of those methods.

grainsizeR interprets size classes and retained proportions or
percentages. It does not automatically understand every
instrument-specific export format. Laser outputs are suitable when they
are converted or exported as retained size-class values. If a laser
instrument exports cumulative percent finer or cumulative percent
passing, the cumulative curve must be converted to retained bin
increments before using
[`read_gsd()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd.md).

## Single-Sample and Multi-Sample Layouts

A single-sample table commonly has one size column and one value column.
A multi-sample wide table commonly has one size column and multiple
sample columns. GRADISTAT-style single-sample input is conceptually
similar to one sample’s size-value table. GRADISTAT-style multi-sample
input is conceptually similar to grainsizeR’s wide-table input, with
size classes as rows and samples as columns.

grainsizeR’s tidy long format is often more convenient for batch
analysis, plotting, joining metadata, and reproducible workflows. This
comparison is about data organization only; it does not copy GRADISTAT
input templates or workbook logic.

## Example Datasets

`grain.wide.csv` is a dry-sieve example stored as a multi-sample wide
table. It has coarser particle-size resolution and a terminal fine
open-ended class.

`grain.long.csv` is a sieve + hydrometer example stored as a tidy long
table. It has finer particle-size resolution for samples where
hydrometer data were added. Hydrometer measurements were added only when
the fraction finer than approximately 0.063 mm exceeded 10%.

Because of that workflow rule, some samples may still be unable to
resolve fine-end D-values, clay thresholds, or other fine-end thresholds
without explicit extrapolation.

Pipette-method and laser-diffraction data can also be imported as wide
or long tables when they are arranged as size-class retained percentages
or proportions. Suitability for clay/silt/sand fractions depends on
whether the required thresholds are resolved by finite measured size
boundaries, not on whether the input file is wide or long.

## Dry-Sieve Example in a Wide Table

``` r
wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")

gs_wide <- read_gsd(
  wide_file,
  format = "wide",
  size_col = 1,
  size_unit = "mm",
  value_type = "percent"
)
#> New names:
#> • `` -> `...1`

head(gs_diagnostics(gs_wide, output = "summary"))
#> # A tibble: 6 × 8
#>   sample_id   n_ok n_warning n_error n_info has_error has_warning overall_status
#>   <chr>      <int>     <int>   <int>  <int> <lgl>     <lgl>       <chr>         
#> 1 Cd1_deeper    23         6       0      2 FALSE     TRUE        warning       
#> 2 Cd1_upper     24         5       0      2 FALSE     TRUE        warning       
#> 3 Cd2_deeper    23         6       0      2 FALSE     TRUE        warning       
#> 4 Cd2_upper     24         5       0      2 FALSE     TRUE        warning       
#> 5 Cd3_deeper    23         6       0      2 FALSE     TRUE        warning       
#> 6 Cd3_upper     24         5       0      2 FALSE     TRUE        warning
```

This example is appropriate for coarse gravel/sand/mud or sand/mud
summaries when relevant thresholds are resolved. Clay and silt
thresholds such as 2, 20, 50, or 60 um may not be resolvable from data
with only a terminal open fine class. Open fine tails should not be
silently treated as bounded intervals.

``` r
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

head(suppressWarnings(gs_parameters(
  gs_wide,
  parameters = c("d_values", "indices", "folk_ward", "fractions"),
  fraction_scheme = "wentworth_major",
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 40
#>   sample_id D5_um D10_um D16_um D25_um D50_um D75_um D84_um D90_um D95_um D30_um
#>   <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
#> 1 Cd1_deep…  59.7   64.7   71.2   82.2   123.   264.   389.   511.  1133.   89.0
#> 2 Cd1_upper  66.6   75.2   87.0  108.    175.   286.   366.   432.   496.  122. 
#> 3 Cd2_deep…  58.7   63.0   68.7   78.1   112.   215.   298.   383.   472.   83.9
#> 4 Cd2_upper  69.6   81.6   98.6  130.    251.   358.   408.   444.   477.  148. 
#> 5 Cd3_deep…  58.7   62.7   67.9   76.5   107.   210.   296.   370.   445.   81.8
#> 6 Cd3_upper  71.8   86.2  107.   142.    261.   365.   412.   447.   478.  161. 
#> # ℹ 29 more variables: D60_um <dbl>, Cu <dbl>, Cc <dbl>, So_trask <dbl>,
#> #   Sk_trask <dbl>, fine_content_percent <dbl>, fine_threshold_um <dbl>,
#> #   fine_equivalent <dbl>, interpolation_scale <chr>, D5_phi <dbl>,
#> #   D16_phi <dbl>, D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>, D84_phi <dbl>,
#> #   D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>, sorting_fw_phi <dbl>,
#> #   skewness_fw <dbl>, kurtosis_fw <dbl>, any_extrapolated <lgl>,
#> #   mean_size_class <chr>, sorting_class <chr>, skewness_class <chr>, …
```

## Sieve + Hydrometer Example in a Long Table

``` r
long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")

gs_long <- read_gsd(
  long_file,
  format = "long",
  sample_col = "sample",
  size_col = "size",
  value_col = "proportion",
  size_unit = "mm",
  value_type = "proportion"
)

head(gs_diagnostics(gs_long, output = "summary"))
#> # A tibble: 6 × 8
#>   sample_id   n_ok n_warning n_error n_info has_error has_warning overall_status
#>   <chr>      <int>     <int>   <int>  <int> <lgl>     <lgl>       <chr>         
#> 1 Cd1_deeper    24         5       0      2 FALSE     TRUE        warning       
#> 2 Cd1_upper     25         4       0      2 FALSE     TRUE        warning       
#> 3 Cd2_deeper    24         5       0      2 FALSE     TRUE        warning       
#> 4 Cd2_upper     25         4       0      2 FALSE     TRUE        warning       
#> 5 Cd3_deeper    24         5       0      2 FALSE     TRUE        warning       
#> 6 Cd3_upper     25         4       0      2 FALSE     TRUE        warning
```

Sieve + hydrometer measurements are often preferred for clay/silt/sand
texture fractions because they can provide finite boundaries in the fine
tail. In this example, hydrometer was only added for samples with enough
fine material, so not every sample necessarily resolves all fine-end
D-values. Unresolved D5 or D95 values should be reported rather than
hidden.

``` r
head(suppressWarnings(gs_fractions_wide(gs_long, scheme = "usda_tt")))
#> # A tibble: 6 × 5
#>   sample_id  gravel_percent sand_percent silt_percent clay_percent
#>   <chr>               <dbl>        <dbl>        <dbl>        <dbl>
#> 1 Cd1_deeper          2.76          97.2            0            0
#> 2 Cd1_upper           1.05          98.9            0            0
#> 3 Cd2_deeper          1.09          98.9            0            0
#> 4 Cd2_upper           0.359         99.6            0            0
#> 5 Cd3_deeper          0.365         99.6            0            0
#> 6 Cd3_upper           0.411         99.6            0            0
head(suppressWarnings(gs_fractions_wide(gs_long, scheme = "uk_ssew")))
#> # A tibble: 6 × 5
#>   sample_id  gravel_percent sand_percent silt_percent clay_percent
#>   <chr>               <dbl>        <dbl>        <dbl>        <dbl>
#> 1 Cd1_deeper          2.76          97.2            0            0
#> 2 Cd1_upper           1.05          98.9            0            0
#> 3 Cd2_deeper          1.09          98.9            0            0
#> 4 Cd2_upper           0.359         99.6            0            0
#> 5 Cd3_deeper          0.365         99.6            0            0
#> 6 Cd3_upper           0.411         99.6            0            0
```

## Why Some Fine-End D-Values Remain Unresolved

Open-ended terminal classes do not provide finite lower or upper
boundaries. If D5 falls inside an open fine tail, or D95 falls inside an
open coarse tail, the default behavior is to report that the value is
unresolved. Users may explicitly request extrapolation, but the
extrapolation decision should be documented.

## Diagnostics Before Analysis

Use diagnostics before clay/silt/sand fractions, D-values near open
tails, or texture classification.

``` r
sample_id <- "WN1_upper"

head(gs_diagnostics(
  gs_long,
  d_values = c(5, 10, 50, 90, 95),
  fraction_schemes = c("wentworth_major", "usda_tt", "uk_ssew")
))
#> # A tibble: 6 × 9
#>   sample_id  check              status severity value expected parameter message
#>   <chr>      <chr>              <chr>  <chr>    <chr> <chr>    <chr>     <chr>  
#> 1 Cd1_deeper missing_values     ok     none     0     finite … NA        Retain…
#> 2 Cd1_deeper negative_values    ok     none     0     no nega… NA        No neg…
#> 3 Cd1_deeper zero_total         ok     none     100   > 0      NA        The re…
#> 4 Cd1_deeper retained_total     ok     none     100   100 +/-… NA        Retain…
#> 5 Cd1_deeper duplicate_size_cl… ok     none     0     0 dupli… NA        No dup…
#> 6 Cd1_deeper size_order         ok     none     decr… coarse-… NA        Size c…
#> # ℹ 1 more variable: recommendation <chr>
```

## Coarse Fractions From the Dry-Sieve Example

For the dry-sieve example, coarse fraction summaries such as Wentworth
gravel, sand, and mud are usually the first summary to inspect.

``` r
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

## Clay/Silt/Sand Fractions From Finer-Resolution Data

Texture-fraction workflows require sufficient fine-resolution data to
resolve the relevant boundaries.

``` r
head(suppressWarnings(gs_fractions_wide(gs_long, scheme = "usda_tt")))
#> # A tibble: 6 × 5
#>   sample_id  gravel_percent sand_percent silt_percent clay_percent
#>   <chr>               <dbl>        <dbl>        <dbl>        <dbl>
#> 1 Cd1_deeper          2.76          97.2            0            0
#> 2 Cd1_upper           1.05          98.9            0            0
#> 3 Cd2_deeper          1.09          98.9            0            0
#> 4 Cd2_upper           0.359         99.6            0            0
#> 5 Cd3_deeper          0.365         99.6            0            0
#> 6 Cd3_upper           0.411         99.6            0            0
head(suppressWarnings(gs_fractions_wide(gs_long, scheme = "uk_ssew")))
#> # A tibble: 6 × 5
#>   sample_id  gravel_percent sand_percent silt_percent clay_percent
#>   <chr>               <dbl>        <dbl>        <dbl>        <dbl>
#> 1 Cd1_deeper          2.76          97.2            0            0
#> 2 Cd1_upper           1.05          98.9            0            0
#> 3 Cd2_deeper          1.09          98.9            0            0
#> 4 Cd2_upper           0.359         99.6            0            0
#> 5 Cd3_deeper          0.365         99.6            0            0
#> 6 Cd3_upper           0.411         99.6            0            0
```

## Summary Tables

[`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md)
creates compact reporting tables from lower-level functions.

``` r
head(suppressWarnings(gs_parameters(
  gs_long[gs_long$sample_id == sample_id, ],
  parameters = c("d_values", "indices", "folk_ward", "fractions"),
  fraction_scheme = "gradistat",
  extrapolate = "warn_linear"
)))
#> # A tibble: 1 × 41
#>   sample_id D5_um D10_um D16_um D25_um D50_um D75_um D84_um D90_um D95_um D30_um
#>   <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
#> 1 WN1_upper  61.8   67.8   75.7   89.4   155.   327.   419.   494.   996.   98.0
#> # ℹ 30 more variables: D60_um <dbl>, Cu <dbl>, Cc <dbl>, So_trask <dbl>,
#> #   Sk_trask <dbl>, fine_content_percent <dbl>, fine_threshold_um <dbl>,
#> #   fine_equivalent <dbl>, interpolation_scale <chr>, D5_phi <dbl>,
#> #   D16_phi <dbl>, D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>, D84_phi <dbl>,
#> #   D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>, sorting_fw_phi <dbl>,
#> #   skewness_fw <dbl>, kurtosis_fw <dbl>, any_extrapolated <lgl>,
#> #   mean_size_class <chr>, sorting_class <chr>, skewness_class <chr>, …
```

GRADISTAT-style D-spread descriptors, retained-class modes, printout
descriptors, and quality flags can be requested explicitly. D-spread
ratios and differences are metric descriptors, modal classes are ranked
by retained class percentage rather than estimated as continuous density
peaks, and quality flags are advisory checks rather than calculation
blockers.

``` r
head(suppressWarnings(gs_d_spread(
  gs_long[gs_long$sample_id == sample_id, ],
  extrapolate = "warn_linear"
)))
#> # A tibble: 1 × 14
#>   sample_id   D10   D25   D50   D75   D90 d_value_unit D90_D10_ratio
#>   <chr>     <dbl> <dbl> <dbl> <dbl> <dbl> <chr>                <dbl>
#> 1 WN1_upper  67.8  89.4  155.  327.  494. um                    7.29
#> # ℹ 6 more variables: D90_minus_D10 <dbl>, D75_D25_ratio <dbl>,
#> #   D75_minus_D25 <dbl>, D90_D10_log_ratio <dbl>, D75_D25_log_ratio <dbl>,
#> #   any_extrapolated <lgl>

head(gs_modes(gs_long[gs_long$sample_id == sample_id, ]))
#> # A tibble: 3 × 12
#>   sample_id sample_modality mode_rank mode_size_mm mode_size_um mode_phi
#>   <chr>     <chr>               <int>        <dbl>        <dbl>    <dbl>
#> 1 WN1_upper bimodal                 1       0.0884         88.4      3.5
#> 2 WN1_upper bimodal                 2       0.354         354.       1.5
#> 3 WN1_upper bimodal                 3       0.177         177.       2.5
#> # ℹ 6 more variables: mode_class_lower_mm <dbl>, mode_class_upper_mm <dbl>,
#> #   mode_percent <dbl>, mode_class_label <chr>, is_open_interval <lgl>,
#> #   mode_status <chr>

head(suppressWarnings(gs_parameters(
  gs_long[gs_long$sample_id == sample_id, ],
  parameters = c("d_spread", "modes", "descriptors", "quality"),
  extrapolate = "warn_linear"
)))
#> # A tibble: 1 × 55
#>   sample_id   D10   D25   D50   D75   D90 d_value_unit D90_D10_ratio
#>   <chr>     <dbl> <dbl> <dbl> <dbl> <dbl> <chr>                <dbl>
#> 1 WN1_upper  67.8  89.4  155.  327.  494. um                    7.29
#> # ℹ 47 more variables: D90_minus_D10 <dbl>, D75_D25_ratio <dbl>,
#> #   D75_minus_D25 <dbl>, D90_D10_log_ratio <dbl>, D75_D25_log_ratio <dbl>,
#> #   any_extrapolated <lgl>, mean_description <chr>, sorting_description <chr>,
#> #   skewness_description <chr>, kurtosis_description <chr>,
#> #   description_method <chr>, description_status <chr>, sample_modality <chr>,
#> #   mode1_size_mm <dbl>, mode1_size_um <dbl>, mode1_phi <dbl>,
#> #   mode1_class_lower_mm <dbl>, mode1_class_upper_mm <dbl>, …
```

## GRADISTAT-Inspired Summary Plots

[`plot_gradistat_summary()`](https://Gavin987.github.io/grainsizeR/reference/plot_gradistat_summary.md)
creates a one-sample diagnostic/report plot. It does not export files;
users can save ggplot objects with standard R tools.

``` r
plot_gradistat_summary(
  gs_long,
  sample_id = sample_id,
  extrapolate = "warn_linear"
)
```

## Recommended Workflow

1.  Read data.
2.  Validate the `gsd_tbl`.
3.  Run
    [`gs_diagnostics()`](https://Gavin987.github.io/grainsizeR/reference/gs_diagnostics.md).
4.  Decide whether the available measurements and table layout are
    appropriate for the target analysis.
5.  Compute D-values, fractions, statistics, and summary tables.
6.  Make diagnostic or report plots.
7.  For future texture classification, use only data with resolved
    clay/silt/sand thresholds or document extrapolation explicitly.

## What This Vignette Does Not Do

This vignette does not add official texture polygon datasets. It does
not perform texture classification using built-in official polygons. It
does not implement civil-engineering classification systems. It does not
silently fill missing fine-tail information. It does not implement
laser-specific import.
