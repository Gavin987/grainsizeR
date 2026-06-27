
# grainsizeR

## Overview

grainsizeR provides R tools for sediment grain-size analysis. It reads
retained grain-size distributions, builds validated `gsd_tbl` objects,
calculates D-values and percent-finer thresholds, summarizes grain-size
statistics and fractions, supports GRADISTAT/G2Sd-style functional
replacement workflows, and creates common plots for sedimentology and
soil texture workflows.

Built-in official texture polygon datasets are not bundled yet.
User-supplied texture polygons are supported. The package scope is
sedimentology, grain-size statistics, particle-size fractions, soil
texture fractions, texture ternary plots, and documented soil or
sediment texture systems.

## Installation

``` r
# Development installation from GitHub.
install.packages("remotes")
remotes::install_github("Gavin987/grainsizeR")
```

grainsizeR is under active development. Built-in official texture
polygon datasets are not bundled yet, and polygon reconstruction
scaffolds under `data-raw/` are development materials.

## Data Format

grainsizeR accepts long and wide retained-size data.

Long format has one row per sample and grain-size class:

``` text
sample,size,proportion
WN1_upper,2,0.023552612
WN1_upper,1,0.026157166
```

Wide format stores size classes in rows and samples in columns. Terminal
fine classes such as `<0.0625` are supported.

## Basic Workflow

``` r
library(grainsizeR)

long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")

if (!nzchar(long_file)) {
  long_file <- file.path("inst", "extdata", "grain.long.csv")
  wide_file <- file.path("inst", "extdata", "grain.wide.csv")
}

gs <- read_gsd(
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

## Example Outputs

The wide dry-sieve example supports a GRADISTAT-style gravel-sand-mud
workflow, including a retained-size distribution with cumulative
overlay, cumulative curves, non-overlapping `Gravel`, `Sand`, and `Mud`
fractions, GRADISTAT `gravel_sand_mud` classification, and a GRADISTAT
texture ternary plot. The long-format example includes finer fractions
and is used for the USDA texture workflow. The USDA ternary plot below
uses clearly labeled demo points and includes bundled long-format
example points when they resolve to valid sand-silt-clay percentages.

The figures below are generated reproducibly by
`data-raw/readme-figures.R` from bundled example data. They are
demonstration outputs, not universal sediment interpretation templates.
Open-ended tails may require explicit `extrapolate = "warn_linear"` for
graphical statistics or percentile markers; grainsizeR does not apply
that assumption silently. Detailed Wentworth-style fraction classes are
available when the input resolution supports them, but dry-sieve data
should not be interpreted as resolving silt and clay subclasses unless
those boundaries are present. USDA and GRADISTAT ternary plots show
classification boundaries with sample points or demonstration points.
USDA ternary plots use external percent-axis labels, while GRADISTAT
gravel-sand-mud ternary plots keep the `Gravel`, `Mud`, and `Sand` apex
labels with GRADISTAT-style gravel and sand/mud ratio guides.
Distribution and cumulative plots use log-scaled particle-size axes by
default, with tick labels shown as plain millimetre values. They are
single-sample plots; select one sample with `sample_id`, then loop or
arrange returned plots externally for multi-sample figures.

<img src="man/figures/readme-wide-distribution.png" width="100%" />

<img src="man/figures/readme-wide-cumulative.png" width="100%" />

<img src="man/figures/readme-wide-fractions.png" width="100%" />

<img src="man/figures/readme-gradistat-ternary.png" width="49%" /><img src="man/figures/readme-usda-ternary.png" width="49%" />

## End-to-End Workflow

The compact workflow below reads retained data, calculates common
replacement outputs, and creates the main plot families. The full
examples are in `vignette("grain-size-workflow")` and
`vignette("replacing-gradistat-g2sd")`.

``` r
gs <- read_gsd(
  long_file,
  format = "long",
  sample_col = "sample",
  size_col = "size",
  value_col = "proportion",
  size_unit = "mm",
  value_type = "proportion"
)

d_values <- gs_d_values(gs, probs = c(10, 50, 90), extrapolate = "warn_linear")
spread <- gs_d_spread(gs, extrapolate = "warn_linear")
folk_ward <- gs_folk_ward(gs, extrapolate = "warn_linear")
modes <- gs_modes(gs)
fractions <- gs_fractions(gs, scheme = "wentworth_major")
descriptors <- gs_describe_parameters(gs)
quality <- gs_quality_flags(gs)

plot_distribution(gs, sample_id = "WN1_upper")
plot_distribution(gs, sample_id = "WN1_upper", cumulative = TRUE)
plot_cumulative(gs, sample_id = "WN1_upper", show_percentiles = c(10, 50, 90), extrapolate = "warn_linear")
plot_fractions(gs, scheme = "wentworth_major")
```

## Data Quality Diagnostics

`gs_diagnostics()` reports retained-total issues, open-ended terminal
bins, and whether requested D-values, thresholds, and fraction schemes
are resolvable without silent open-tail assumptions.

``` r
head(gs_diagnostics(gs_wide, output = "summary"))
#> # A tibble: 6 × 8
#>   sample_id   n_ok n_warning n_error n_info has_error has_warning overall_status
#>   <chr>      <int>     <int>   <int>  <int> <lgl>     <lgl>       <chr>         
#> 1 Cd1_deeper    19        10       0      2 FALSE     TRUE        warning       
#> 2 Cd1_upper     20         9       0      2 FALSE     TRUE        warning       
#> 3 Cd2_deeper    19        10       0      2 FALSE     TRUE        warning       
#> 4 Cd2_upper     20         9       0      2 FALSE     TRUE        warning       
#> 5 Cd3_deeper    19        10       0      2 FALSE     TRUE        warning       
#> 6 Cd3_upper     20         9       0      2 FALSE     TRUE        warning

head(gs_diagnostics(
  gs,
  d_values = c(5, 10, 50, 90, 95),
  fraction_schemes = c("wentworth_major", "usda_tt", "uk_ssew")
))
#> # A tibble: 6 × 9
#>   sample_id  check              status severity value expected parameter message
#>   <chr>      <chr>              <chr>  <chr>    <chr> <chr>    <chr>     <chr>  
#> 1 Cd1_deeper missing_values     ok     none     0     finite … <NA>      Retain…
#> 2 Cd1_deeper negative_values    ok     none     0     no nega… <NA>      No neg…
#> 3 Cd1_deeper zero_total         ok     none     100   > 0      <NA>      The re…
#> 4 Cd1_deeper retained_total     ok     none     100   100 +/-… <NA>      Retain…
#> 5 Cd1_deeper duplicate_size_cl… ok     none     0     0 dupli… <NA>      No dup…
#> 6 Cd1_deeper size_order         ok     none     decr… coarse-… <NA>      Size c…
#> # ℹ 1 more variable: recommendation <chr>
```

## Table Layouts and Measurement Workflows

grainsizeR supports both tidy long tables and multi-sample wide tables.
These file layouts are independent of measurement workflow. The included
`grain.wide.csv` file demonstrates a dry-sieve dataset stored as a
multi-sample wide table. The included `grain.long.csv` file demonstrates
a sieve + hydrometer dataset stored as a tidy long table.

Pipette-method and laser-diffraction data may also be stored as wide or
long tables. Laser outputs reported as volume percent by bin can usually
be represented as retained class values after checking bin definitions.
Laser cumulative outputs must be converted to retained bin increments
before import. Use `gs_diagnostics()` to determine whether target
thresholds and D-values are resolvable. Clay/silt/sand texture workflows
require sufficient fine-resolution data.

## D-Values and Percent Finer

`D_p` is the grain size at which `p` percent of the sample is finer.

``` r
head(gs_d_values(gs, probs = c(10, 50, 90)))
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

head(suppressWarnings(gs_percent_finer(
  gs,
  sizes = c(2, 20, 50, 60, 63),
  size_unit = "um",
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 8
#>   sample_id  threshold_um threshold_mm threshold_phi percent_finer
#>   <chr>             <dbl>        <dbl>         <dbl>         <dbl>
#> 1 Cd1_deeper            2        0.002          8.97       -207.  
#> 2 Cd1_deeper           20        0.02           5.64        -63.4 
#> 3 Cd1_deeper           50        0.05           4.32         -6.09
#> 4 Cd1_deeper           60        0.06           4.06          5.32
#> 5 Cd1_deeper           63        0.063          3.99          8.37
#> 6 Cd1_upper             2        0.002          8.97       -140.  
#> # ℹ 3 more variables: percent_coarser <dbl>, interpolation_scale <chr>,
#> #   extrapolated <lgl>
```

Percent-finer thresholds do not need to match measured class boundaries.
Values are interpolated between finite boundaries. Open-ended terminal
classes are not silently treated as bounded intervals.

## Grain-Size Indices

``` r
head(suppressWarnings(gs_grain_size_indices(
  gs,
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 15
#>   sample_id  D10_um D25_um D30_um D50_um D60_um D75_um    Cu    Cc So_trask
#>   <chr>       <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl>    <dbl>
#> 1 Cd1_deeper   64.7   82.2   89.0   123.   164.   264.  2.53 0.748     1.79
#> 2 Cd1_upper    75.2  108.   122.    175.   209.   286.  2.78 0.949     1.63
#> 3 Cd2_deeper   63.0   78.1   83.9   112.   134.   215.  2.13 0.834     1.66
#> 4 Cd2_upper    81.6  130.   148.    251.   289.   358.  3.54 0.932     1.66
#> 5 Cd3_deeper   62.7   76.5   81.8   107.   122.   210.  1.94 0.876     1.66
#> 6 Cd3_upper    86.2  142.   161.    261.   298.   365.  3.46 1.01      1.60
#> # ℹ 5 more variables: Sk_trask <dbl>, fine_content_percent <dbl>,
#> #   fine_threshold_um <dbl>, fine_equivalent <dbl>, interpolation_scale <chr>
```

## Folk and Ward Statistics

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

## Moment Statistics and Open-Ended Classes

Moment statistics require explicit handling of open-ended terminal
classes.

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

## Grain-Size Fractions

``` r
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
head(particle_size_systems())
#> # A tibble: 6 × 15
#>   system_id     system_name country_or_region domain clay_upper_um silt_upper_um
#>   <chr>         <chr>       <chr>             <chr>          <dbl>         <dbl>
#> 1 wentworth_ma… Wentworth … International     sedim…            NA            NA
#> 2 gradistat     GRADISTAT … International     sedim…             4            63
#> 3 usda_tt       USDA textu… United States     soil …             2            50
#> 4 isss          Internatio… International     soil …             2            20
#> 5 uk_ssew       UK SSEW pa… United Kingdom    soil …             2            60
#> 6 hypres        HYPRES par… Europe            soil …             2            50
#> # ℹ 9 more variables: sand_upper_um <dbl>, gravel_lower_um <dbl>,
#> #   clay_range <chr>, silt_range <chr>, sand_range <chr>, gravel_range <chr>,
#> #   source_status <chr>, source_reference <chr>, notes <chr>
```

## Summary Tables

`gs_parameters()` returns ordinary R tabular output that can be used
directly in reports or exported with standard R functions.

``` r
summary <- suppressWarnings(gs_parameters(
  gs,
  parameters = c("d_values", "indices", "folk_ward", "fractions"),
  fraction_scheme = "gradistat",
  extrapolate = "warn_linear"
))

head(summary)
#> # A tibble: 6 × 42
#>   sample_id D5_um D10_um D16_um D25_um D50_um D75_um D84_um D90_um D95_um D30_um
#>   <chr>     <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
#> 1 Cd1_deep…  59.7   64.7   71.2   82.2   123.   264.   389.   511.  1133.   89.0
#> 2 Cd1_upper  66.6   75.2   87.0  108.    175.   286.   366.   432.   496.  122. 
#> 3 Cd2_deep…  58.7   63.0   68.7   78.1   112.   215.   298.   383.   472.   83.9
#> 4 Cd2_upper  69.6   81.6   98.6  130.    251.   358.   408.   444.   477.  148. 
#> 5 Cd3_deep…  58.7   62.7   67.9   76.5   107.   210.   296.   370.   445.   81.8
#> 6 Cd3_upper  71.8   86.2  107.   142.    261.   365.   412.   447.   478.  161. 
#> # ℹ 31 more variables: D60_um <dbl>, Cu <dbl>, Cc <dbl>, So_trask <dbl>,
#> #   Sk_trask <dbl>, fine_content_percent <dbl>, fine_threshold_um <dbl>,
#> #   fine_equivalent <dbl>, interpolation_scale <chr>, D5_phi <dbl>,
#> #   D16_phi <dbl>, D25_phi <dbl>, D50_phi <dbl>, D75_phi <dbl>, D84_phi <dbl>,
#> #   D95_phi <dbl>, mean_fw_phi <dbl>, mean_fw_um <dbl>, sorting_fw_phi <dbl>,
#> #   skewness_fw <dbl>, kurtosis_fw <dbl>, any_extrapolated <lgl>,
#> #   mean_size_class <chr>, sorting_class <chr>, skewness_class <chr>, …
```

GRADISTAT-style D-spread descriptors, retained-class modes, printout
descriptors, and quality flags are available as explicit summaries:

``` r
head(suppressWarnings(gs_d_spread(gs, extrapolate = "warn_linear")))
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

They can also be requested from `gs_parameters()`:

``` r
head(suppressWarnings(gs_parameters(
  gs,
  parameters = c("d_spread", "modes", "descriptors", "quality"),
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 55
#>   sample_id    D10   D25   D50   D75   D90 d_value_unit D90_D10_ratio
#>   <chr>      <dbl> <dbl> <dbl> <dbl> <dbl> <chr>                <dbl>
#> 1 Cd1_deeper  64.7  82.2  123.  264.  511. um                    7.91
#> 2 Cd1_upper   75.2 108.   175.  286.  432. um                    5.75
#> 3 Cd2_deeper  63.0  78.1  112.  215.  383. um                    6.08
#> 4 Cd2_upper   81.6 130.   251.  358.  444. um                    5.45
#> 5 Cd3_deeper  62.7  76.5  107.  210.  370. um                    5.90
#> 6 Cd3_upper   86.2 142.   261.  365.  447. um                    5.18
#> # ℹ 47 more variables: D90_minus_D10 <dbl>, D75_D25_ratio <dbl>,
#> #   D75_minus_D25 <dbl>, D90_D10_log_ratio <dbl>, D75_D25_log_ratio <dbl>,
#> #   any_extrapolated <lgl>, mean_description <chr>, sorting_description <chr>,
#> #   skewness_description <chr>, kurtosis_description <chr>,
#> #   description_method <chr>, description_status <chr>, sample_modality <chr>,
#> #   mode1_size_mm <dbl>, mode1_size_um <dbl>, mode1_phi <dbl>,
#> #   mode1_class_lower_mm <dbl>, mode1_class_upper_mm <dbl>, …
```

``` r
write.csv(summary, "grain_size_summary.csv", row.names = FALSE)
```

grainsizeR intentionally does not provide a dedicated
`export_gradistat_summary()` helper; export format choices are left to
standard R workflows.

## GRADISTAT and G2Sd Workflows

grainsizeR provides R-native workflows for many tasks commonly handled
in GRADISTAT and G2Sd-style grain-size analysis. The package covers
retained-data import, D-values, percent-finer interpolation, grain-size
indices, GRADISTAT-style D-spread descriptors, retained-class modes,
Folk and Ward statistics, moment statistics, descriptive terms, quality
flags, particle-size fractions, summary tables, and distribution,
cumulative, fraction, texture ternary, and summary plots.

These workflows are functional R replacements, not Excel printout
clones. The package does not copy GRADISTAT VBA code, G2Sd source code,
workbook chart objects, or spreadsheet layouts. CRAN readiness is not
claimed.

## Validation and Numerical Assumptions

The method-validation vignette documents the D-value convention,
threshold interpolation, open-tail behavior, long/wide example-data
interpretation, and summary-table consistency. Read it before comparing
grainsizeR results with other software.

## Plotting

``` r
plot_distribution(gs, sample_id = "WN1_upper")
plot_distribution(gs, sample_id = "WN1_upper", cumulative = TRUE)
plot_distribution(gs, sample_id = "WN1_upper", x_scale = "phi", type = "line")
plot_cumulative(gs, sample_id = "WN1_upper", show_percentiles = c(10, 50, 90), extrapolate = "warn_linear")
plot_cumulative(gs, sample_id = "WN1_upper", x_scale = "phi")
plot_fractions(gs, scheme = "wentworth_major")
```

Metric distribution and cumulative plots use particle size in
millimetres on a log-scaled x-axis by default, with major breaks at
0.001, 0.01, 0.1, and 1 mm. Use `particle_unit = "um"` to show the same
axis in micrometres. They plot one sample at a time; use `sample_id` or
filter the input first, then loop over samples or combine plots
externally with a plotting-arrangement package if needed.

### GRADISTAT-Inspired Summary Plot

`plot_gradistat_summary()` creates an original sediment grain-size
diagnostic plot for a single sample. It combines retained distribution,
cumulative percent finer, D-value markers, fraction boundaries, and a
compact summary caption.

``` r
plot_gradistat_summary(gs, sample_id = "WN1_upper", extrapolate = "warn_linear")
```

## USDA Major Texture Classes

USDA 12-class major textural classification is available through the
existing `classify_texture()` workflow. It uses the validated internal
rule helper and does not require bundled USDA polygon data.

``` r
samples <- data.frame(
  sample_id = c("A", "B", "C"),
  sand = c(85, 40, 20),
  silt = c(10, 40, 20),
  clay = c(5, 20, 60)
)

classify_texture(samples, scheme = "usda_tt", method = "rules")
#> # A tibble: 3 × 11
#>   sample_id  sand  silt  clay texture_class_id texture_class
#>   <chr>     <dbl> <dbl> <dbl> <chr>            <chr>        
#> 1 A            85    10     5 loamy_sand       loamy sand   
#> 2 B            40    40    20 loam             loam         
#> 3 C            20    20    60 clay             clay         
#> # ℹ 5 more variables: classification_method <chr>, rule_status <chr>,
#> #   all_rule_matches <chr>, rule_conflict <lgl>, rule_gap <lgl>
```

``` r
usda_plot_gs <- as_gsd_tbl(
  data.frame(
    sample_id = "A",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.031, 0.016, 0.008, 0.004, 0.002, 0.001),
    retained = c(2, 3, 5, 10, 15, 18, 12, 10, 8, 7, 6, 4)
  ),
  sample_id,
  size_mm,
  retained,
  value_type = "percent"
)

plot_texture_ternary(usda_plot_gs, scheme = "usda_tt")
```

`method = "auto"` selects the same USDA rule path for
`scheme = "usda_tt"` when no texture polygons are supplied.

This path covers only the 12 USDA major classes. Sand-size modifier
subclasses such as coarse sand, fine sand, very fine sand, coarse sandy
loam, fine sandy loam, and very fine sandy loam are not implemented yet.
They may be considered later as qualitative descriptor columns for D50
or particle-size summaries. No USDA polygon dataset is bundled. The rule
path is vectorized; current performance notes are informational and are
not formal benchmarks.

## GRADISTAT Texture Classification

GRADISTAT-style texture classification is available through the existing
`classify_texture()` workflow. The supported rule bases are
`gravel_sand_mud` for gravel-sand-mud textural groups and
`sand_silt_clay_no_gravel` for no-gravel sand-silt-clay mini texture
classes. GRADISTAT-style sediment-name composition is available with
`gs_gradistat_sediment_name()` or by setting
`include_sediment_name = TRUE` in the GRADISTAT classification call.

``` r
gsm <- data.frame(
  sample_id = c("A", "B", "C"),
  gravel = c(0, 10, 40),
  sand = c(95, 80, 40),
  mud = c(5, 10, 20)
)

classify_texture(
  gsm,
  scheme = "gradistat",
  method = "rules",
  basis = "gravel_sand_mud",
  include_sediment_name = TRUE
)
#> # A tibble: 3 × 21
#>   sample_id gravel  sand   mud texture_class_id    texture_class   ternary_basis
#>   <chr>      <dbl> <dbl> <dbl> <chr>               <chr>           <chr>        
#> 1 A              0    95     5 sand                sand            gravel_sand_…
#> 2 B             10    80    10 gravelly_muddy_sand gravelly muddy… gravel_sand_…
#> 3 C             40    40    20 muddy_sandy_gravel  muddy sandy gr… gravel_sand_…
#> # ℹ 14 more variables: classification_method <chr>,
#> #   classification_status <chr>, notes <chr>, sand_mud_ratio <dbl>,
#> #   textural_group_class_id <chr>, textural_group <chr>,
#> #   mini_texture_class_id <chr>, mini_texture_class <chr>,
#> #   dominant_gravel_class <chr>, dominant_sand_class <chr>,
#> #   dominant_silt_class <chr>, sediment_name <chr>, sediment_name_status <chr>,
#> #   sediment_name_method <chr>
```

`TEXTURAL GROUP` and `SEDIMENT NAME` are distinct GRADISTAT-style
outputs. When dominant size-subclass columns are missing, grainsizeR
returns the textural group as a partial sediment name rather than
inventing subclass modifiers. GRADISTAT ternary plotting is available
through the preferred `plot_texture_ternary()` alias. The stable
`plot_texture_triangle()` function name remains available for
compatibility. USDA classification remains available separately through
`scheme = "usda_tt"`. GRADISTAT gravel-sand-mud ternary plots place
`Gravel` at the top, `Mud` at the lower-left apex, and `Sand` at the
lower-right apex.

``` r
plot_texture_ternary(
  gsm,
  scheme = "gradistat",
  basis = "gravel_sand_mud",
  point_id = "sample_id"
)
```

## Texture Ternary Plots and User-Supplied Polygons

Texture class polygons are separate from particle-size fraction schemes.
grainsizeR does not include official polygon coordinates yet, but users
can provide their own polygons.

Source-audit helpers list planned texture systems and source-review
status:

``` r
texture_polygon_sources()
#> # A tibble: 11 × 9
#>    scheme       scheme_name  particle_size_system left_component right_component
#>    <chr>        <chr>        <chr>                <chr>          <chr>          
#>  1 usda_tt      USDA textur… usda_tt              sand           silt           
#>  2 hypres       HYPRES text… hypres               sand           silt           
#>  3 isss         Internation… isss                 sand           silt           
#>  4 uk_ssew      UK SSEW tex… uk_ssew              sand           silt           
#>  5 gradistat    GRADISTAT t… gradistat            sand           silt           
#>  6 australia_20 Australia 2… australia_20         sand           silt           
#>  7 germany_63   Germany 63 … germany_63           sand           silt           
#>  8 canada_50    Canada 50 u… canada_50            sand           silt           
#>  9 belgium_50   Belgium 50 … belgium_50           sand           silt           
#> 10 fr_aisne     French Aisn… fr_aisne             sand           silt           
#> 11 fr_geppa     French GEPP… fr_geppa             sand           silt           
#> # ℹ 4 more variables: top_component <chr>, polygon_status <chr>,
#> #   primary_source <chr>, notes <chr>
texture_source_audit()
#> # A tibble: 21 × 18
#>    scheme    scheme_name domain particle_size_system clay_upper_um silt_upper_um
#>    <chr>     <chr>       <chr>  <chr>                        <dbl>         <dbl>
#>  1 usda_tt   USDA textu… soil … usda_tt                          2            50
#>  2 hypres    HYPRES tex… soil … hypres                           2            50
#>  3 isss      Internatio… soil … isss                             2            20
#>  4 uk_ssew   UK SSEW te… soil … uk_ssew                          2            60
#>  5 gradistat GRADISTAT … sedim… gradistat                        4            63
#>  6 australi… Australia … soil … australia_20                     2            20
#>  7 germany_… Germany 63… soil … germany_63                       2            63
#>  8 sweden_60 Sweden 60 … soil … sweden_60                        2            60
#>  9 canada_50 Canada 50 … soil … canada_50                        2            50
#> 10 belgium_… Belgium 50… soil … belgium_50                       2            50
#> # ℹ 11 more rows
#> # ℹ 12 more variables: sand_upper_um <dbl>, left_component <chr>,
#> #   right_component <chr>, top_component <chr>, texture_polygon_status <chr>,
#> #   fraction_scheme_status <chr>, primary_source_status <chr>,
#> #   primary_source_short <chr>, primary_source_full <chr>,
#> #   secondary_source_note <chr>, implementation_note <chr>,
#> #   include_in_package <lgl>
```

No official texture polygon dataset is bundled. Future built-in polygon
data would need a separate source review, independent reconstruction
from primary official or academic sources, validation examples, tests,
and package documentation. Soil Texture Wizard or other secondary
references may help find sources, but they are not coordinate sources
for grainsizeR.

USDA major 12-class texture classification is available through
`classify_texture(..., scheme = "usda_tt", method = "rules")`. This is a
rule-based classifier, not a bundled USDA polygon dataset.

``` r
synthetic <- data.frame(
  sample_id = rep(c("A", "B"), each = 4),
  size_mm = rep(c(2, 0.05, 0.002, 0.001), 2),
  retained = c(10, 40, 30, 20, 5, 20, 35, 40)
)

synthetic_gs <- as_gsd_tbl(
  synthetic,
  sample_id,
  size_mm,
  retained,
  value_type = "percent"
)

polygons <- data.frame(
  scheme = "synthetic_ternary",
  class_id = "all",
  class_name = "Synthetic full ternary area",
  vertex_id = 1:3,
  left = c(100, 0, 0),
  right = c(0, 100, 0),
  top = c(0, 0, 100),
  left_component = "sand",
  right_component = "silt",
  top_component = "clay",
  reference_id = NA_character_,
  reference = NA_character_
)

polygons <- validate_texture_polygons(polygons)
classify_texture(synthetic_gs, polygons, scheme = "synthetic_ternary")
plot_texture_ternary(synthetic_gs, polygons = polygons, scheme = "synthetic_ternary")
```

## Convenience Aliases

Full descriptive function names remain the recommended names in most
documentation. Short aliases are available for interactive use and do
not change behavior. Common aliases include `gs_fw57()` for
`gs_folk_ward()`, `gs_frac()` for `gs_fractions()`, `gs_diag()` for
`gs_diagnostics()`, and `plot_texture_ternary()` for texture ternary
plots. `plot_texture_triangle()` remains available as a stable
compatibility function name.

| Task | Preferred function | Shortcut or compatibility name |
|----|----|----|
| Folk and Ward statistics | `gs_folk_ward()` | `gs_fw57()`, `gs_folkward()` |
| Fraction summaries | `gs_fractions()` | `gs_frac()` |
| Fraction scheme list | `gs_fraction_schemes()` | `gs_frac_schemes()` |
| Wide fraction table | `gs_fractions_wide()` | `gs_frac_wide()` |
| Diagnostics | `gs_diagnostics()` | `gs_diag()` |
| Descriptive terms | `gs_describe_parameters()` | `gs_desc()` |
| Quality flags | `gs_quality_flags()` | `gs_qc()` |
| D-values | `gs_d_values()` | `gs_percentile()` |
| Texture ternary plot | `plot_texture_ternary()` | `plot_texture_triangle()`, `plot_trigon()` |

## License and Data Provenance

grainsizeR is licensed under the MIT License. Package code and original
package documentation are MIT-licensed.

Future built-in official texture polygon datasets are not bundled yet.
Official polygon datasets will only be added after independent
reconstruction from primary official or academic sources, review,
testing, and documentation. Secondary resources may be used as
source-finding guides only.

grainsizeR will not copy `soiltexture` code, class tables, internal data
objects, vertex tables, polygon coordinates, or internal polygon
definitions. The public provenance notes in `data-raw/provenance/`
document source boundaries before any future built-in texture polygon
dataset is considered.

## Current Limitations

- Built-in official texture polygon datasets are not included yet.
- Full Excel visual parity for GRADISTAT and G2Sd plot outputs is not
  claimed.
- CRAN readiness is not claimed; it requires a separate future audit.
- Open-ended terminal classes require explicit extrapolation or
  unresolved-value handling.
- The package focuses on sedimentology, grain-size statistics,
  particle-size fractions, soil texture fractions, texture ternary
  plots, and documented soil/sediment texture systems.

## Development Status

grainsizeR is in active development. Function names and documentation
are being polished before broader release, while compatibility aliases
are retained for earlier development names.
