# Validate user-supplied texture polygons

`validate_texture_polygons()` checks the schema and coordinate
consistency of user-supplied ternary texture polygons. Polygon
coordinates must be supplied by users or future cited data sources; this
package does not vendor polygon coordinates from external R packages.

## Usage

``` r
validate_texture_polygons(polygons)
```

## Arguments

- polygons:

  A data frame containing texture polygon vertices.

## Value

A validated tibble with class `texture_polygons`.
