# Convert a reconstruction table to texture polygons

`reconstruction_to_texture_polygons()` converts a completed texture
polygon reconstruction table into the compact schema used by
[`validate_texture_polygons()`](https://Gavin987.github.io/grainsizeR/reference/validate_texture_polygons.md).
This helper is intended for future official polygon reconstruction
workflows and does not provide built-in polygon data.

## Usage

``` r
reconstruction_to_texture_polygons(x, validate = TRUE, require_ready = FALSE)
```

## Arguments

- x:

  A data frame with columns from
  [`texture_polygon_reconstruction_template()`](https://Gavin987.github.io/grainsizeR/reference/texture_polygon_reconstruction_template.md).

- validate:

  Should the compact polygon table be validated with
  [`validate_texture_polygons()`](https://Gavin987.github.io/grainsizeR/reference/validate_texture_polygons.md)
  before returning?

- require_ready:

  Should rows be required to have `implementation_status` equal to
  `"ready_for_package"` or `"implemented"`?

## Value

A tibble with compact texture polygon columns. If `validate = TRUE`, the
result also has class `texture_polygons`.
