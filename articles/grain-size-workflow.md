# Grain-Size Analysis Workflow

## Overview

This vignette shows a compact end-to-end grain-size workflow with
grainsizeR. It uses the example files installed with the package and
keeps each step as an ordinary R object so results can be checked,
joined, plotted, and exported with standard R tools.

This vignette uses preferred public functions in the main workflow.
Short aliases are available for interactive use, but the full function
names are easier to read in scripts and reports. CRAN readiness is not
claimed here.

``` r
library(grainsizeR)
```

## Reading Long and Wide Grain-Size Data

Long input has one row per sample and size class. Wide input has one
size column and one column per sample.

``` r
long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")

gs <- read_gsd(
  long_file,
  format = "long",
  sample_col = "sample",
  size_col = "size",
  value_col = "proportion",
  size_unit = "mm",
  value_type = "proportion"
)

gs_wide <- read_gsd_wide(
  wide_file,
  size_col = 1,
  size_unit = "mm",
  value_type = "percent"
)
#> New names:
#> • `` -> `...1`

head(gs)
#> # A tibble: 6 × 13
#>   sample_id  bin_id raw_size_um size_lower_um size_upper_um size_mid_um
#>   <chr>       <int>       <dbl>         <dbl>         <dbl>       <dbl>
#> 1 Cd1_deeper      1      2000          2000              NA        NA  
#> 2 Cd1_deeper      2      1000          1000            2000      1414. 
#> 3 Cd1_deeper      3       500           500            1000       707. 
#> 4 Cd1_deeper      4       250           250             500       354. 
#> 5 Cd1_deeper      5       125           125             250       177. 
#> 6 Cd1_deeper      6        62.5          62.5           125        88.4
#> # ℹ 7 more variables: size_mid_phi <dbl>, retained_percent <dbl>,
#> #   cum_finer_percent <dbl>, cum_coarser_percent <dbl>, is_open_lower <lgl>,
#> #   is_open_upper <lgl>, measurement_method <chr>
```

## Inspecting and Validating `gsd_tbl` Objects

[`read_gsd()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd.md)
and
[`read_gsd_wide()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd_wide.md)
return `gsd_tbl` objects. Diagnostics help identify open-ended classes
and threshold-resolution limits before running a large analysis.

``` r
is_gsd_tbl(gs)
#> [1] TRUE
head(gs_diagnostics(gs, output = "summary"))
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

## Cumulative Percentages

[`gs_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/gs_cumulative.md)
returns finite-boundary cumulative percentages by sample.

``` r
head(gs_cumulative(gs))
#> # A tibble: 6 × 7
#>   sample_id  boundary_id boundary_um boundary_mm boundary_phi percent_finer
#>   <chr>            <int>       <dbl>       <dbl>        <dbl>         <dbl>
#> 1 Cd1_deeper           1      2000        2                -1         97.2 
#> 2 Cd1_deeper           2      1000        1                 0         94.5 
#> 3 Cd1_deeper           3       500        0.5               1         89.8 
#> 4 Cd1_deeper           4       250        0.25              2         73.7 
#> 5 Cd1_deeper           5       125        0.125             3         51.2 
#> 6 Cd1_deeper           6        62.5      0.0625            4          7.87
#> # ℹ 1 more variable: percent_coarser <dbl>
```

## D-Values and GRADISTAT-Style D-Spread Descriptors

Use
[`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)
for requested percentiles and
[`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md)
for GRADISTAT-style D-ratio and D-difference descriptors. Open-ended
tails require an explicit extrapolation choice when a requested value
falls outside resolved boundaries.

``` r
head(suppressWarnings(gs_d_values(
  gs,
  probs = c(10, 50, 90),
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 7
#>   sample_id  percentile grain_size_um grain_size_mm grain_size_phi
#>   <chr>           <dbl>         <dbl>         <dbl>          <dbl>
#> 1 Cd1_deeper         10          64.7        0.0647          3.95 
#> 2 Cd1_deeper         50         123.         0.123           3.03 
#> 3 Cd1_deeper         90         511.         0.511           0.967
#> 4 Cd1_upper          10          75.2        0.0752          3.73 
#> 5 Cd1_upper          50         175.         0.175           2.51 
#> 6 Cd1_upper          90         432.         0.432           1.21 
#> # ℹ 2 more variables: interpolation_scale <chr>, extrapolated <lgl>

head(suppressWarnings(gs_d_spread(
  gs,
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 14
#>   sample_id    D10   D25   D50   D75   D90 d_value_unit D90_D10_ratio
#>   <chr>      <dbl> <dbl> <dbl> <dbl> <dbl> <chr>                <dbl>
#> 1 Cd1_deeper  64.7  82.2  123.  264.  511. um                    7.91
#> 2 Cd1_upper   75.2 108.   175.  286.  432. um                    5.75
#> 3 Cd2_deeper  63.0  78.1  112.  215.  383. um                    6.08
#> 4 Cd2_upper   81.6 130.   251.  358.  444. um                    5.45
#> 5 Cd3_deeper  62.7  76.5  107.  210.  370. um                    5.90
#> 6 Cd3_upper   86.2 142.   261.  365.  447. um                    5.18
#> # ℹ 6 more variables: D90_minus_D10 <dbl>, D75_D25_ratio <dbl>,
#> #   D75_minus_D25 <dbl>, D90_D10_log_ratio <dbl>, D75_D25_log_ratio <dbl>,
#> #   any_extrapolated <lgl>
```

## Folk and Ward Graphical Statistics

[`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md)
calculates graphical statistics from percentile estimates.

``` r
head(suppressWarnings(gs_folk_ward(
  gs,
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 26
#>   sample_id  D5_um D16_um D25_um D50_um D75_um D84_um D95_um D5_phi D16_phi
#>   <chr>      <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>   <dbl>
#> 1 Cd1_deeper  59.7   71.2   82.2   123.   264.   389.  1133.   4.07    3.81
#> 2 Cd1_upper   66.6   87.0  108.    175.   286.   366.   496.   3.91    3.52
#> 3 Cd2_deeper  58.7   68.7   78.1   112.   215.   298.   472.   4.09    3.86
#> 4 Cd2_upper   69.6   98.6  130.    251.   358.   408.   477.   3.84    3.34
#> 5 Cd3_deeper  58.7   67.9   76.5   107.   210.   296.   445.   4.09    3.88
#> 6 Cd3_upper   71.8  107.   142.    261.   365.   412.   478.   3.80    3.22
#> # ℹ 16 more variables: D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>,
#> #   D84_phi <dbl>, D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>,
#> #   sorting_fw_phi <dbl>, skewness_fw <dbl>, kurtosis_fw <dbl>,
#> #   interpolation_scale <chr>, any_extrapolated <lgl>, mean_size_class <chr>,
#> #   sorting_class <chr>, skewness_class <chr>, kurtosis_class <chr>
```

## Moment Statistics

Moment statistics require explicit open-end handling. This example
extends terminal classes by one phi unit.

``` r
head(suppressWarnings(gs_moments(
  gs,
  open_end = "extend_phi"
)))
#> # A tibble: 6 × 14
#>   sample_id  moment_method   mean_moment mean_moment_unit mean_moment_um
#>   <chr>      <chr>                 <dbl> <chr>                     <dbl>
#> 1 Cd1_deeper logarithmic_phi        2.64 phi                        160.
#> 2 Cd1_upper  logarithmic_phi        2.45 phi                        183.
#> 3 Cd2_deeper logarithmic_phi        2.91 phi                        133.
#> 4 Cd2_upper  logarithmic_phi        2.22 phi                        214.
#> 5 Cd3_deeper logarithmic_phi        2.98 phi                        127.
#> 6 Cd3_upper  logarithmic_phi        2.15 phi                        225.
#> # ℹ 9 more variables: mean_moment_phi <dbl>, sd_moment <dbl>,
#> #   sd_moment_unit <chr>, skewness_moment <dbl>, kurtosis_moment <dbl>,
#> #   retained_percent_used <dbl>, open_end <chr>, open_end_estimated <lgl>,
#> #   open_end_omitted <lgl>
```

## Modes and Sample Modality

[`gs_modes()`](https://Gavin987.github.io/grainsizeR/reference/gs_modes.md)
reports ranked retained-class modes and an operational modality label.

``` r
head(gs_modes(gs))
#> # A tibble: 6 × 12
#>   sample_id  sample_modality mode_rank mode_size_mm mode_size_um mode_phi
#>   <chr>      <chr>               <int>        <dbl>        <dbl>    <dbl>
#> 1 Cd1_deeper bimodal                 1       0.0884         88.4      3.5
#> 2 Cd1_deeper bimodal                 2       0.177         177.       2.5
#> 3 Cd1_deeper bimodal                 3       0.354         354.       1.5
#> 4 Cd1_upper  unimodal                1       0.177         177.       2.5
#> 5 Cd1_upper  unimodal                2       0.0884         88.4      3.5
#> 6 Cd1_upper  unimodal                3       0.354         354.       1.5
#> # ℹ 6 more variables: mode_class_lower_mm <dbl>, mode_class_upper_mm <dbl>,
#> #   mode_percent <dbl>, mode_class_label <chr>, is_open_interval <lgl>,
#> #   mode_status <chr>
```

## Fraction Summaries

Fraction summaries can be returned in long or wide form. The long form
is convenient for plotting and joins; the wide form is convenient for
reports. The dry-sieve wide example is useful for GRADISTAT-style
gravel-sand-mud summaries. The long example includes finer fractions and
is used later for USDA texture workflows.

``` r
head(gs_fractions(gs, scheme = "wentworth_major"))
#> # A tibble: 6 × 11
#>   sample_id  scheme        component lower_mm upper_mm lower_um upper_um percent
#>   <chr>      <chr>         <chr>        <dbl>    <dbl>    <dbl>    <dbl>   <dbl>
#> 1 Cd1_deeper wentworth_ma… gravel      2      Inf        2000      Inf      2.76
#> 2 Cd1_deeper wentworth_ma… sand        0.0625   2          62.5   2000     89.4 
#> 3 Cd1_deeper wentworth_ma… mud         0        0.0625      0       62.5    7.87
#> 4 Cd1_upper  wentworth_ma… gravel      2      Inf        2000      Inf      1.05
#> 5 Cd1_upper  wentworth_ma… sand        0.0625   2          62.5   2000     96.6 
#> 6 Cd1_upper  wentworth_ma… mud         0        0.0625      0       62.5    2.37
#> # ℹ 3 more variables: normalize <chr>, interpolation_scale <chr>,
#> #   resolved <lgl>
head(gs_fractions_wide(gs, scheme = "wentworth_major"))
#> # A tibble: 6 × 4
#>   sample_id  gravel_percent sand_percent mud_percent
#>   <chr>               <dbl>        <dbl>       <dbl>
#> 1 Cd1_deeper          2.76          89.4        7.87
#> 2 Cd1_upper           1.05          96.6        2.37
#> 3 Cd2_deeper          1.09          89.5        9.42
#> 4 Cd2_upper           0.359         98.1        1.57
#> 5 Cd3_deeper          0.365         89.9        9.75
#> 6 Cd3_upper           0.411         98.4        1.22
head(gs_fractions_wide(gs_wide, scheme = "gradistat"))
#> # A tibble: 6 × 5
#>   sample_id  gravel_percent sand_percent silt_percent clay_percent
#>   <chr>               <dbl>        <dbl>        <dbl>        <dbl>
#> 1 Cd1_deeper          2.76          88.9         8.37            0
#> 2 Cd1_upper           1.05          96.2         2.70            0
#> 3 Cd2_deeper          1.09          88.9         9.97            0
#> 4 Cd2_upper           0.359         97.8         1.82            0
#> 5 Cd3_deeper          0.365         89.3        10.4             0
#> 6 Cd3_upper           0.411         98.2         1.44            0
```

## Descriptive Terms

[`gs_describe_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_describe_parameters.md)
adds GRADISTAT-style printout descriptors for calculated Folk and Ward
or moment statistics.

``` r
head(suppressWarnings(gs_describe_parameters(gs)))
#> # A tibble: 6 × 19
#>   sample_id  bin_id raw_size_um size_lower_um size_upper_um size_mid_um
#>   <chr>       <int>       <dbl>         <dbl>         <dbl>       <dbl>
#> 1 Cd1_deeper      1      2000          2000              NA        NA  
#> 2 Cd1_deeper      2      1000          1000            2000      1414. 
#> 3 Cd1_deeper      3       500           500            1000       707. 
#> 4 Cd1_deeper      4       250           250             500       354. 
#> 5 Cd1_deeper      5       125           125             250       177. 
#> 6 Cd1_deeper      6        62.5          62.5           125        88.4
#> # ℹ 13 more variables: size_mid_phi <dbl>, retained_percent <dbl>,
#> #   cum_finer_percent <dbl>, cum_coarser_percent <dbl>, is_open_lower <lgl>,
#> #   is_open_upper <lgl>, measurement_method <chr>, mean_description <chr>,
#> #   sorting_description <chr>, skewness_description <chr>,
#> #   kurtosis_description <chr>, description_method <chr>,
#> #   description_status <chr>
```

## Quality Flags

[`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md)
records advisory flags for supplied sediment loss and open-ended fine
pan fractions.

``` r
head(gs_quality_flags(
  gs,
  sediment_loss_percent = c(WN1_upper = 1.5, WN2_upper = 2.5)
))
#> # A tibble: 6 × 6
#>   sample_id  quality_flag      quality_status    quality_value quality_threshold
#>   <chr>      <chr>             <chr>             <chr>         <chr>            
#> 1 Cd1_deeper sediment_loss     not_evaluated     NA            > 2%             
#> 2 Cd1_deeper open_fine_tail    needs_additional… TRUE          reported explici…
#> 3 Cd1_deeper fine_pan_fraction warning           7.8719146     1% info; 5% warn…
#> 4 Cd1_upper  sediment_loss     not_evaluated     NA            > 2%             
#> 5 Cd1_upper  open_fine_tail    needs_additional… TRUE          reported explici…
#> 6 Cd1_upper  fine_pan_fraction needs_additional… 2.3733818     1% info; 5% warn…
#> # ℹ 1 more variable: quality_message <chr>
```

## Distribution Plots

[`plot_distribution()`](https://Gavin987.github.io/grainsizeR/reference/plot_distribution.md)
returns a ggplot object and supports metric and phi axis scales. The
same function can overlay cumulative percent finer on the retained
size-class bars for a GRADISTAT-style combined display. The examples
below use the dry-sieve wide dataset so the plotted samples align with
the README GRADISTAT-style showcase. Metric displays use particle size
in millimetres on a log-scaled x-axis by default, with major breaks at
0.001, 0.01, 0.1, 1, and 10 mm. Distribution bars are centered at
particle-size classes. Use `particle_unit = "um"` for micrometre axes.
Distribution and cumulative plots show one sample at a time; loop over
samples or arrange returned plots externally for multi-sample figures.
Lower open-ended classes are displayed at 0.0015 mm, or 1.5 um, for
plotting only; calculations are unchanged.

``` r
plot_distribution(gs_wide, sample_id = "WN1_upper")
```

![](grain-size-workflow_files/figure-html/unnamed-chunk-12-1.png)

``` r
plot_distribution(gs_wide, sample_id = "WN1_upper", cumulative = TRUE)
```

![](grain-size-workflow_files/figure-html/unnamed-chunk-12-2.png)

``` r
plot_distribution(gs_wide, x_scale = "phi", type = "line", sample_id = "WN1_upper")
```

![](grain-size-workflow_files/figure-html/unnamed-chunk-12-3.png)

## Cumulative Plots

[`plot_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/plot_cumulative.md)
uses the same particle-size x-axis conventions and can also add D-value
markers.

``` r
suppressWarnings(plot_cumulative(
  gs_wide,
  sample_id = "WN1_upper",
  show_percentiles = c(10, 50, 90),
  extrapolate = "warn_linear"
))
```

![](grain-size-workflow_files/figure-html/unnamed-chunk-13-1.png)

## Fraction Plots

[`plot_fractions()`](https://Gavin987.github.io/grainsizeR/reference/plot_fractions.md)
draws size-class percentage bars. For dry-sieve GRADISTAT-style
examples, use non-overlapping `Gravel`, `Sand`, and `Mud` fractions.
More detailed Wentworth-style classes are available with
`scheme = "wentworth_detailed"` when the input resolves those
boundaries.

``` r
plot_fractions(
  gs_wide,
  scheme = "gravel_sand_mud",
  sample_id = c("WN1_upper", "WN2_upper"),
  fill_palette = "YlOrBr"
)
```

![](grain-size-workflow_files/figure-html/unnamed-chunk-14-1.png)

## Building a Combined Analysis Table

[`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md)
collects common outputs into a single table. More specialized helpers
remain available when you need a narrower result.

``` r
combined <- suppressWarnings(gs_parameters(
  gs,
  parameters = c("d_values", "d_spread", "folk_ward", "modes", "descriptors", "quality"),
  d_values = c(10, 50, 90),
  extrapolate = "warn_linear",
  moments_open_end = "extend_phi"
))

head(combined)
#> # A tibble: 6 × 81
#>   sample_id  D10_um D50_um D90_um   D10   D25   D50   D75   D90 d_value_unit
#>   <chr>       <dbl>  <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <chr>       
#> 1 Cd1_deeper   64.7   123.   511.  64.7  82.2  123.  264.  511. um          
#> 2 Cd1_upper    75.2   175.   432.  75.2 108.   175.  286.  432. um          
#> 3 Cd2_deeper   63.0   112.   383.  63.0  78.1  112.  215.  383. um          
#> 4 Cd2_upper    81.6   251.   444.  81.6 130.   251.  358.  444. um          
#> 5 Cd3_deeper   62.7   107.   370.  62.7  76.5  107.  210.  370. um          
#> 6 Cd3_upper    86.2   261.   447.  86.2 142.   261.  365.  447. um          
#> # ℹ 71 more variables: D90_D10_ratio <dbl>, D90_minus_D10 <dbl>,
#> #   D75_D25_ratio <dbl>, D75_minus_D25 <dbl>, D90_D10_log_ratio <dbl>,
#> #   D75_D25_log_ratio <dbl>, any_extrapolated <lgl>, D5_um <dbl>, D16_um <dbl>,
#> #   D25_um <dbl>, D75_um <dbl>, D84_um <dbl>, D95_um <dbl>, D5_phi <dbl>,
#> #   D16_phi <dbl>, D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>, D84_phi <dbl>,
#> #   D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>, sorting_fw_phi <dbl>,
#> #   skewness_fw <dbl>, kurtosis_fw <dbl>, interpolation_scale <chr>, …
```

## Notes on Open-Ended Tails and Extrapolation

Open-ended terminal classes are common in sediment data. grainsizeR does
not silently turn them into closed intervals. Functions that need
unresolved thresholds require an explicit extrapolation or open-end
option, which makes the assumption visible in the analysis script.
