# Compose GRADISTAT-style sediment names

`gs_gradistat_sediment_name()` appends GRADISTAT-style sediment-name
fields to a data frame. It is intended for data already classified with
`classify_texture(..., scheme = "gradistat", method = "rules")`, or for
data frames containing the GRADISTAT major components needed to compute
the textural group. `TEXTURAL GROUP` and `SEDIMENT NAME` are distinct
outputs: the textural group is the gravel-sand-mud or no-gravel
sand-silt-clay class, while the sediment name may add dominant
size-subclass wording when those subclass percentages are supplied.

## Usage

``` r
gs_gradistat_sediment_name(
  x,
  basis = c("auto", "gravel_sand_mud", "sand_silt_clay_no_gravel")
)
```

## Arguments

- x:

  A data frame. It may be output from
  [`classify_texture()`](https://Gavin987.github.io/grainsizeR/reference/classify_texture.md)
  for `scheme = "gradistat"`, or it may contain `gravel`, `sand`, and
  `mud` columns, `sand`, `silt`, and `clay` columns, or both.

- basis:

  Preferred classification basis. `"auto"` uses an existing
  `ternary_basis` column when present, otherwise it prefers
  `"gravel_sand_mud"` when `gravel`, `sand`, and `mud` are available and
  `"sand_silt_clay_no_gravel"` when only `sand`, `silt`, and `clay` are
  available.

## Value

A tibble containing the input rows with `textural_group_class_id`,
`textural_group`, `mini_texture_class_id`, `mini_texture_class`,
`dominant_gravel_class`, `dominant_sand_class`, `dominant_silt_class`,
`sediment_name`, `sediment_name_status`, `sediment_name_method`, and
`notes` appended or updated.

## Details

The function re-expresses decision-table behavior recorded from the
user-provided GRADISTAT v8 workbook and Blott and Pye (2001). It does
not copy VBA source code. GRADISTAT ternary plotting is handled
separately and is not implemented by this function.

## Examples

``` r
classified <- classify_texture(
  data.frame(
    sample_id = "A",
    gravel = 0,
    sand = 95,
    mud = 5,
    fine_sand = 70,
    medium_sand = 25
  ),
  scheme = "gradistat",
  method = "rules",
  basis = "gravel_sand_mud"
)

gs_gradistat_sediment_name(classified)
#> # A tibble: 1 × 23
#>   sample_id gravel  sand   mud fine_sand medium_sand texture_class_id
#>   <chr>      <dbl> <dbl> <dbl>     <dbl>       <dbl> <chr>           
#> 1 A              0    95     5        70          25 sand            
#> # ℹ 16 more variables: texture_class <chr>, ternary_basis <chr>,
#> #   classification_method <chr>, classification_status <chr>, notes <chr>,
#> #   sand_mud_ratio <dbl>, textural_group_class_id <chr>, textural_group <chr>,
#> #   mini_texture_class_id <chr>, mini_texture_class <chr>,
#> #   dominant_gravel_class <chr>, dominant_sand_class <chr>,
#> #   dominant_silt_class <chr>, sediment_name <chr>, sediment_name_status <chr>,
#> #   sediment_name_method <chr>
```
