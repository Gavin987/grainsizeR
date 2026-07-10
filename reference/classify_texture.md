# Classify samples with texture classes

`classify_texture()` classifies samples with either the validated
internal USDA 12-class major texture rules or user-supplied texture
polygon vertices. USDA rule classification is available with
`scheme = "usda"` and `method = "rules"` or `method = "auto"`. The USDA
path uses sand, silt, and clay percentages and covers only the 12 major
USDA texture ternary classes. GRADISTAT-style rule classification is
available with `scheme = "gradistat"` and `method = "rules"` or
`method = "auto"`. It supports `basis = "gravel_sand_mud"` for physical
sediment textural groups and `basis = "sand_silt_clay_no_gravel"` for
no-gravel sand-silt-clay mini texture classes. When `x` is a `gsd_tbl`,
USDA and GRADISTAT rule paths derive the needed fractions from the
normalized particle-size scale stored in the object; users do not need
to choose size units in texture functions after import. The GRADISTAT
path re-expresses user-provided GRADISTAT v8 workbook decision tables in
R and does not copy VBA source code. Full downstream sediment-name
composition is supported separately and GRADISTAT ternary plotting is
available through
[`plot_texture_ternary()`](https://gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md).

## Usage

``` r
classify_texture(
  x,
  polygons = NULL,
  scheme = NULL,
  method = c("auto", "rules", "polygon"),
  texture_polygons = NULL,
  normalize = "none",
  interpolation_scale = "phi",
  unresolved = "warn_na",
  extrapolate = "error",
  components = NULL,
  basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel"),
  include_sediment_name = FALSE
)
```

## Arguments

- x:

  A valid `gsd_tbl` object, or for USDA rule classification a data frame
  with numeric `sand`, `silt`, and `clay` percentage columns. Official
  `gs_fractions_wide(..., scheme = "usda")` output with `sand_percent`,
  `silt_percent`, and `clay_percent` columns is also accepted. Data
  frames with ternary `left`, `right`, and `top` columns are accepted
  for USDA rules and are mapped as `left = sand`, `right = silt`, and
  `top = clay`. For polygon classification, `x` must be a `gsd_tbl`.

- polygons:

  User-supplied texture polygon data. This legacy positional argument is
  equivalent to `texture_polygons`.

- scheme:

  Texture classification scheme. Use `"usda"` with `method = "rules"` or
  `method = "auto"` for USDA major texture rules. Use `"gradistat"` with
  `method = "rules"` or `method = "auto"` for GRADISTAT-style rule
  classification. Other non-USDA schemes require user-supplied polygons
  because no built-in texture polygon datasets are bundled.

- method:

  Classification method. `"auto"` uses USDA rules when
  `scheme = "usda"`, or GRADISTAT rules when `scheme = "gradistat"` and
  no polygons are supplied, and polygon classification when polygons are
  supplied. `"rules"` selects a supported rule classifier. `"polygon"`
  selects user-supplied polygon classification.

- texture_polygons:

  User-supplied texture polygon data.

- normalize:

  Normalization mode passed to
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- interpolation_scale:

  Interpolation scale passed to
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- unresolved:

  Unresolved-threshold behavior passed to
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- extrapolate:

  Extrapolation behavior passed to
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- components:

  Optional named character vector mapping left, right, and top ternary
  axes to fraction components.

- basis:

  Rule-classification basis. For `scheme = "gradistat"`, use
  `"gravel_sand_mud"` with `gravel`, `sand`, and `mud` columns, or
  `"sand_silt_clay_no_gravel"` with `sand`, `silt`, and `clay` columns.
  USDA classification ignores this argument.

- include_sediment_name:

  Logical. For GRADISTAT rule classification, `TRUE` appends
  GRADISTAT-style sediment-name fields using
  [`gs_gradistat_sediment_name()`](https://gavin987.github.io/grainsizeR/reference/gs_gradistat_sediment_name.md).
  Missing subclass columns produce a partial sediment-name status
  instead of invented modifiers. USDA and polygon classification ignore
  this argument.

## Value

A tibble with one row per sample and texture class assignment. USDA rule
classification returns the input rows with `texture_class_id`,
`texture_class`, `classification_method`, `rule_status`,
`all_rule_matches`, `rule_conflict`, and `rule_gap` appended. For valid
USDA inputs, `classification_method` is `"usda_major_rules"` and
`rule_status` is `"classified"`. GRADISTAT rule classification returns
the input rows with `texture_class_id`, `texture_class`,
`classification_method`, `classification_status`, `ternary_basis`,
`notes`, and a ratio audit column appended. If
`include_sediment_name = TRUE`, GRADISTAT outputs also include
`sediment_name` and related sediment-name audit columns. Polygon
classification also uses `texture_class_id` and `texture_class` for the
public classification result, while retaining polygon-specific
component, coordinate, and status columns such as `left`, `right`,
`top`, `x`, `y`, `resolved`, and `ambiguous`.

## Details

For rule-based paths, input percentages must be numeric, finite, between
0 and 100, and sum to approximately 100; the function does not silently
normalize invalid sums. It does not implement sand-size modifier
subclasses such as coarse sand, fine sand, very fine sand, coarse sandy
loam, fine sandy loam, or very fine sandy loam. Those may be added later
as qualitative descriptor columns for D50 or particle-size summaries.

Generic polygon classification remains available by supplying
`texture_polygons` or the legacy positional `polygons` argument. No
built-in USDA polygon dataset is bundled.

## Examples

``` r
samples <- data.frame(
  sample_id = c("A", "B", "C"),
  sand = c(85, 40, 20),
  silt = c(10, 40, 20),
  clay = c(5, 20, 60)
)

classify_texture(samples, scheme = "usda", method = "rules")
#> # A tibble: 3 × 11
#>   sample_id  sand  silt  clay texture_class_id texture_class
#>   <chr>     <dbl> <dbl> <dbl> <chr>            <chr>        
#> 1 A            85    10     5 loamy_sand       loamy sand   
#> 2 B            40    40    20 loam             loam         
#> 3 C            20    20    60 clay             clay         
#> # ℹ 5 more variables: classification_method <chr>, rule_status <chr>,
#> #   all_rule_matches <chr>, rule_conflict <lgl>, rule_gap <lgl>
classify_texture(samples, scheme = "usda", method = "auto")
#> # A tibble: 3 × 11
#>   sample_id  sand  silt  clay texture_class_id texture_class
#>   <chr>     <dbl> <dbl> <dbl> <chr>            <chr>        
#> 1 A            85    10     5 loamy_sand       loamy sand   
#> 2 B            40    40    20 loam             loam         
#> 3 C            20    20    60 clay             clay         
#> # ℹ 5 more variables: classification_method <chr>, rule_status <chr>,
#> #   all_rule_matches <chr>, rule_conflict <lgl>, rule_gap <lgl>

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

ssc <- data.frame(
  sample_id = c("A", "B", "C"),
  sand = c(95, 60, 20),
  silt = c(3, 30, 60),
  clay = c(2, 10, 20)
)

classify_texture(
  ssc,
  scheme = "gradistat",
  method = "rules",
  basis = "sand_silt_clay_no_gravel"
)
#> # A tibble: 3 × 11
#>   sample_id  sand  silt  clay texture_class_id texture_class ternary_basis      
#>   <chr>     <dbl> <dbl> <dbl> <chr>            <chr>         <chr>              
#> 1 A            95     3     2 sand             sand          sand_silt_clay_no_…
#> 2 B            60    30    10 silty_sand       silty sand    sand_silt_clay_no_…
#> 3 C            20    60    20 sandy_silt       sandy silt    sand_silt_clay_no_…
#> # ℹ 4 more variables: classification_method <chr>, classification_status <chr>,
#> #   notes <chr>, silt_clay_ratio <dbl>

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

synthetic <- data.frame(
  sample_id = rep("A", 4),
  size_mm = c(2, 0.05, 0.002, 0.001),
  retained = c(10, 40, 30, 20)
)
synthetic_gs <- as_gsd_tbl(
  synthetic,
  sample_id,
  size_mm,
  retained,
  value_type = "percent"
)
classify_texture(
  synthetic_gs,
  texture_polygons = polygons,
  scheme = "synthetic_ternary",
  method = "polygon"
)
#> # A tibble: 1 × 13
#>   sample_id scheme  texture_class_id texture_class  left right   top     x     y
#>   <chr>     <chr>   <chr>            <chr>         <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 A         synthe… all              Synthetic fu…    40    30    20 0.444 0.192
#> # ℹ 4 more variables: resolved <lgl>, ambiguous <lgl>, normalize <chr>,
#> #   interpolation_scale <chr>
```
