# Replacing GRADISTAT and G2Sd Workflows

## Purpose

This vignette shows how grainsizeR can be used as an R-native functional
replacement workflow for many GRADISTAT and G2Sd-style grain-size
analysis tasks. It is not an Excel visual clone and does not claim
byte-for-byte parity with workbook printouts.

``` r
library(grainsizeR)
```

## What GRADISTAT and G2Sd Workflows Usually Provide

Typical workflows include importing retained grain-size data,
calculating D-values and graphical statistics, describing sediment
parameters, checking quality cautions, classifying texture, composing
sediment names, and producing distribution, cumulative, fraction, and
texture ternary plots.

## grainsizeR Equivalent Functions

| GRADISTAT / G2Sd output              | grainsizeR function                                                                                                                                                                | Notes                                                                                                                                                                           |
|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Retained grain-size input            | [`read_gsd()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd.md), [`read_gsd_wide()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd_wide.md)                 | Long and wide retained tables are supported.                                                                                                                                    |
| D-values                             | [`gs_d_values()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_values.md)                                                                                                  | Percentile grain sizes with explicit extrapolation behavior.                                                                                                                    |
| D-ratio and D-difference descriptors | [`gs_d_spread()`](https://Gavin987.github.io/grainsizeR/reference/gs_d_spread.md)                                                                                                  | GRADISTAT-style spread descriptors.                                                                                                                                             |
| Folk and Ward statistics             | [`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md)                                                                                                | Graphical statistics in R tabular output.                                                                                                                                       |
| Moment statistics                    | [`gs_moments()`](https://Gavin987.github.io/grainsizeR/reference/gs_moments.md)                                                                                                    | Explicit open-end handling is required.                                                                                                                                         |
| Modes and modality                   | [`gs_modes()`](https://Gavin987.github.io/grainsizeR/reference/gs_modes.md)                                                                                                        | Ranked retained-class modes and sample modality.                                                                                                                                |
| Fraction percentages                 | [`gs_fractions()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions.md), [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md) | Built-in particle-size schemes.                                                                                                                                                 |
| Descriptive terms                    | [`gs_describe_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_describe_parameters.md)                                                                            | GRADISTAT-style printout descriptors.                                                                                                                                           |
| Quality cautions                     | [`gs_quality_flags()`](https://Gavin987.github.io/grainsizeR/reference/gs_quality_flags.md)                                                                                        | Sediment loss and open fine-pan advisories.                                                                                                                                     |
| Summary table                        | [`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md)                                                                                              | Combined R table for reporting.                                                                                                                                                 |
| Distribution plot                    | [`plot_distribution()`](https://Gavin987.github.io/grainsizeR/reference/plot_distribution.md)                                                                                      | ggplot output with metric and phi scales.                                                                                                                                       |
| Cumulative curve                     | [`plot_cumulative()`](https://Gavin987.github.io/grainsizeR/reference/plot_cumulative.md)                                                                                          | ggplot output with optional D-value markers.                                                                                                                                    |
| Fraction plot                        | [`plot_fractions()`](https://Gavin987.github.io/grainsizeR/reference/plot_fractions.md)                                                                                            | ggplot stacked bars by sample.                                                                                                                                                  |
| Texture classification               | [`classify_texture()`](https://Gavin987.github.io/grainsizeR/reference/classify_texture.md)                                                                                        | USDA and GRADISTAT rule paths plus user polygons.                                                                                                                               |
| Sediment names                       | [`gs_gradistat_sediment_name()`](https://Gavin987.github.io/grainsizeR/reference/gs_gradistat_sediment_name.md)                                                                    | GRADISTAT-style composition from texture classes.                                                                                                                               |
| Texture ternary plots                | [`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)                                                                                | Preferred terminology-correct alias; [`plot_texture_triangle()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_triangle.md) remains available for compatibility. |

Short aliases such as
[`gs_fw57()`](https://Gavin987.github.io/grainsizeR/reference/gs_fw57.md),
[`gs_frac()`](https://Gavin987.github.io/grainsizeR/reference/gs_frac.md),
[`gs_diag()`](https://Gavin987.github.io/grainsizeR/reference/gs_diag.md),
and
[`gs_qc()`](https://Gavin987.github.io/grainsizeR/reference/gs_qc.md)
are available for interactive work. The full names in the table remain
the clearest choices for reproducible scripts and method descriptions.

## Input Data

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

gs_wide <- read_gsd(wide_file, format = "wide")
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

The wide dry-sieve example is used below for the GRADISTAT-style
gravel-sand-mud workflow. The long example includes finer fractions and
is used for USDA texture examples. Open-ended tails are not silently
extrapolated; calls that need extrapolation use
`extrapolate = "warn_linear"` explicitly.

## Summary Statistics

``` r
head(suppressWarnings(gs_parameters(
  gs,
  parameters = c("d_values", "indices", "folk_ward", "fractions"),
  d_values = c(10, 50, 90),
  fraction_scheme = "gradistat",
  extrapolate = "warn_linear"
)))
#> # A tibble: 6 × 41
#>   sample_id  D10_um D50_um D90_um D25_um D30_um D60_um D75_um    Cu    Cc
#>   <chr>       <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl>  <dbl> <dbl> <dbl>
#> 1 Cd1_deeper   64.7   123.   511.   82.2   89.0   164.   264.  2.53 0.748
#> 2 Cd1_upper    75.2   175.   432.  108.   122.    209.   286.  2.78 0.949
#> 3 Cd2_deeper   63.0   112.   383.   78.1   83.9   134.   215.  2.13 0.834
#> 4 Cd2_upper    81.6   251.   444.  130.   148.    289.   358.  3.54 0.932
#> 5 Cd3_deeper   62.7   107.   370.   76.5   81.8   122.   210.  1.94 0.876
#> 6 Cd3_upper    86.2   261.   447.  142.   161.    298.   365.  3.46 1.01 
#> # ℹ 31 more variables: So_trask <dbl>, Sk_trask <dbl>,
#> #   fine_content_percent <dbl>, fine_threshold_um <dbl>, fine_equivalent <dbl>,
#> #   interpolation_scale <chr>, D5_um <dbl>, D16_um <dbl>, D84_um <dbl>,
#> #   D95_um <dbl>, D5_phi <dbl>, D16_phi <dbl>, D25_phi <dbl>, D50_phi <dbl>,
#> #   D75_phi <dbl>, D84_phi <dbl>, D95_phi <dbl>, mean_fw_phi <dbl>,
#> #   mean_fw_um <dbl>, sorting_fw_phi <dbl>, skewness_fw <dbl>,
#> #   kurtosis_fw <dbl>, any_extrapolated <lgl>, mean_size_class <chr>, …
```

## D-Values and Spread Descriptors

``` r
head(suppressWarnings(gs_d_values(gs, probs = c(10, 50, 90), extrapolate = "warn_linear")))
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
```

## Modes and Modality

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

## Descriptive Terms and Quality Flags

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
head(gs_quality_flags(gs, sediment_loss_percent = c(WN1_upper = 1.2, WN2_upper = 2.4)))
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

## Texture Classification

USDA major texture classification uses sand, silt, and clay percentages.
USDA sand-size modifier subclasses remain future work.

``` r
usda_fractions <- suppressWarnings(gs_fractions_wide(
  gs,
  scheme = "usda_tt",
  extrapolate = "warn_linear"
))

usda_samples <- data.frame(
  sample_id = usda_fractions$sample_id,
  sand = usda_fractions$sand_percent,
  silt = usda_fractions$silt_percent,
  clay = usda_fractions$clay_percent
)
usda_components <- c("sand", "silt", "clay")
usda_samples <- usda_samples[
  stats::complete.cases(usda_samples[usda_components]) &
    rowSums(usda_samples[usda_components] >= 0 & usda_samples[usda_components] <= 100) == 3 &
    abs(rowSums(usda_samples[usda_components]) - 100) < 1e-6,
]

head(classify_texture(usda_samples, scheme = "usda_tt", method = "rules"))
#> # A tibble: 0 × 11
#> # ℹ 11 variables: sample_id <chr>, sand <dbl>, silt <dbl>, clay <dbl>,
#> #   texture_class_id <chr>, texture_class <chr>, classification_method <chr>,
#> #   rule_status <chr>, all_rule_matches <chr>, rule_conflict <lgl>,
#> #   rule_gap <lgl>
```

GRADISTAT texture classification supports the gravel-sand-mud and
sand-silt-clay no-gravel bases.

``` r
gradistat_fractions <- suppressWarnings(gs_fractions_wide(gs_wide, scheme = "gravel_sand_mud"))

gsm <- data.frame(
  sample_id = gradistat_fractions$sample_id,
  gravel = gradistat_fractions$gravel_percent,
  sand = gradistat_fractions$sand_percent,
  mud = gradistat_fractions$mud_percent
)
gsm <- gsm[stats::complete.cases(gsm[c("gravel", "sand", "mud")]), ]

ssc <- data.frame(
  sample_id = c("A", "B", "C"),
  sand = c(95, 60, 20),
  silt = c(3, 30, 60),
  clay = c(2, 10, 20)
)

gsm_classified <- classify_texture(
  head(gsm, 6),
  scheme = "gradistat",
  method = "rules",
  basis = "gravel_sand_mud",
  include_sediment_name = TRUE
)

ssc_classified <- classify_texture(
  ssc,
  scheme = "gradistat",
  method = "rules",
  basis = "sand_silt_clay_no_gravel"
)

gsm_classified
#> # A tibble: 6 × 21
#>   sample_id  gravel  sand   mud texture_class_id     texture_class ternary_basis
#>   <chr>       <dbl> <dbl> <dbl> <chr>                <chr>         <chr>        
#> 1 Cd1_deeper  2.76   89.4  7.87 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 2 Cd1_upper   1.05   96.6  2.37 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 3 Cd2_deeper  1.09   89.5  9.42 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 4 Cd2_upper   0.359  98.1  1.57 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 5 Cd3_deeper  0.365  89.9  9.75 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 6 Cd3_upper   0.411  98.4  1.22 slightly_gravelly_s… slightly gra… gravel_sand_…
#> # ℹ 14 more variables: classification_method <chr>,
#> #   classification_status <chr>, notes <chr>, sand_mud_ratio <dbl>,
#> #   textural_group_class_id <chr>, textural_group <chr>,
#> #   mini_texture_class_id <chr>, mini_texture_class <chr>,
#> #   dominant_gravel_class <chr>, dominant_sand_class <chr>,
#> #   dominant_silt_class <chr>, sediment_name <chr>, sediment_name_status <chr>,
#> #   sediment_name_method <chr>
ssc_classified
#> # A tibble: 3 × 11
#>   sample_id  sand  silt  clay texture_class_id texture_class ternary_basis      
#>   <chr>     <dbl> <dbl> <dbl> <chr>            <chr>         <chr>              
#> 1 A            95     3     2 sand             sand          sand_silt_clay_no_…
#> 2 B            60    30    10 silty_sand       silty sand    sand_silt_clay_no_…
#> 3 C            20    60    20 sandy_silt       sandy silt    sand_silt_clay_no_…
#> # ℹ 4 more variables: classification_method <chr>, classification_status <chr>,
#> #   notes <chr>, silt_clay_ratio <dbl>
```

## Sediment Names

``` r
gs_gradistat_sediment_name(gsm_classified)
#> # A tibble: 6 × 21
#>   sample_id  gravel  sand   mud texture_class_id     texture_class ternary_basis
#>   <chr>       <dbl> <dbl> <dbl> <chr>                <chr>         <chr>        
#> 1 Cd1_deeper  2.76   89.4  7.87 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 2 Cd1_upper   1.05   96.6  2.37 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 3 Cd2_deeper  1.09   89.5  9.42 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 4 Cd2_upper   0.359  98.1  1.57 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 5 Cd3_deeper  0.365  89.9  9.75 slightly_gravelly_s… slightly gra… gravel_sand_…
#> 6 Cd3_upper   0.411  98.4  1.22 slightly_gravelly_s… slightly gra… gravel_sand_…
#> # ℹ 14 more variables: classification_method <chr>,
#> #   classification_status <chr>, notes <chr>, sand_mud_ratio <dbl>,
#> #   textural_group_class_id <chr>, textural_group <chr>,
#> #   mini_texture_class_id <chr>, mini_texture_class <chr>,
#> #   dominant_gravel_class <chr>, dominant_sand_class <chr>,
#> #   dominant_silt_class <chr>, sediment_name <chr>, sediment_name_status <chr>,
#> #   sediment_name_method <chr>
```

## Distribution and Cumulative Plots

Metric distribution and cumulative plots use particle size in
millimetres on a log-scaled x-axis by default, with major breaks at
0.001, 0.01, 0.1, 1, and 10 mm. Distribution bars are centered at
particle-size classes. Use `particle_unit = "um"` for micrometre axes.
They show one sample at a time; loop over samples or arrange returned
plots externally for multi-sample figures. Lower open-ended classes are
displayed at 0.0015 mm, or 1.5 um, for plotting only; calculations are
unchanged.

``` r
plot_distribution(gs_wide, sample_id = "WN1_upper", cumulative = TRUE)
```

![](replacing-gradistat-g2sd_files/figure-html/unnamed-chunk-10-1.png)

``` r
suppressWarnings(plot_cumulative(
  gs_wide,
  sample_id = "WN1_upper",
  show_percentiles = c(10, 50, 90),
  extrapolate = "warn_linear"
))
```

![](replacing-gradistat-g2sd_files/figure-html/unnamed-chunk-10-2.png)

``` r
plot_fractions(
  gs_wide,
  scheme = "gravel_sand_mud",
  sample_id = c("WN1_upper", "WN2_upper"),
  fill_palette = "YlOrBr"
)
```

![](replacing-gradistat-g2sd_files/figure-html/unnamed-chunk-10-3.png)

## Texture Ternary Plots

GRADISTAT gravel-sand-mud ternary plots place `Gravel` at the top, `Mud`
at the lower-left apex, and `Sand` at the lower-right apex. The plotting
functions draw ternary guides for gravel percentage and sand/mud ratio
directly on the diagram and suppress ordinary Cartesian x/y axes.

``` r
plot_texture_ternary(
  gsm_classified,
  scheme = "gradistat",
  basis = "gravel_sand_mud",
  point_id = "sample_id"
)
```

![](replacing-gradistat-g2sd_files/figure-html/unnamed-chunk-11-1.png)

``` r

plot_texture_ternary(
  ssc_classified,
  scheme = "gradistat",
  basis = "sand_silt_clay_no_gravel",
  point_id = "sample_id"
)
```

![](replacing-gradistat-g2sd_files/figure-html/unnamed-chunk-11-2.png)

## What Differs From Excel-Based GRADISTAT

grainsizeR returns R objects, not fixed spreadsheet worksheets. Plots
are ggplot objects and can be styled or combined with ordinary R tools.
The package does not copy GRADISTAT VBA code, chart objects, or workbook
printout layouts.

## What Is Not Claimed

This vignette does not claim full Excel visual parity, byte-for-byte
output identity, complete modified Udden-Wentworth subclass parity, or a
CRAN release claim. It demonstrates a functional replacement workflow
for the implemented package scope.

## Remaining Future Work

Future work includes a separate CRAN-specific audit before any CRAN
submission and deferred features such as USDA sand-size modifier
subclasses, additional texture systems, and civil-engineering
classifications if they are scoped later.

## Reproducibility Advantages in R

An R-native workflow keeps import choices, extrapolation assumptions,
classification settings, plots, and output tables in a script. That
makes the analysis easier to rerun, review, and version-control than a
manual spreadsheet workflow.
