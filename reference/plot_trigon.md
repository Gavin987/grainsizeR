# Plot samples on a ternary diagram

`plot_trigon()` is retained for legacy compatibility with earlier
grainsizeR texture plotting workflows. Prefer
[`plot_texture_ternary()`](https://gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)
in new code. Unlike
[`plot_texture_ternary()`](https://gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md),
this function can still calculate ternary fractions from a raw `gsd_tbl`
for legacy built-in schemes. Optional user-supplied polygons can be
drawn as overlays. For USDA major texture classes, the function draws
internal rule-derived class boundaries without depending on external
texture plotting packages.

## Usage

``` r
plot_trigon(
  x,
  scheme = "gradistat",
  components = NULL,
  normalize = "none",
  sample_id = NULL,
  labels = TRUE,
  polygons = NULL,
  show_polygons = TRUE,
  show_polygon_labels = TRUE,
  polygon_alpha = 0.15,
  classify = FALSE,
  show_boundaries = TRUE,
  show_classes = TRUE,
  show_class_labels = show_classes,
  sample_label_size = 3,
  class_label_size = 4,
  point_size = 1.8,
  point_color = "black",
  point_alpha = 0.8,
  color_by = NULL
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- scheme:

  Fraction or user polygon scheme.

- components:

  Optional character vector of three component names in left, right, top
  order.

- normalize:

  Normalization mode passed to
  [`gs_fractions_wide()`](https://gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

- sample_id:

  Optional character vector of sample identifiers to include.

- labels:

  Should sample labels be drawn?

- polygons:

  Optional user-supplied texture polygon data.

- show_polygons:

  Should supplied polygons be drawn?

- show_polygon_labels:

  Should polygon class labels be drawn?

- polygon_alpha:

  Fill alpha for polygon overlays.

- classify:

  Should sample points be classified with
  [`classify_texture()`](https://gavin987.github.io/grainsizeR/reference/classify_texture.md)?

- show_boundaries:

  Should built-in rule boundaries be drawn where available?

- show_classes:

  Should built-in class labels be drawn where available?

- show_class_labels:

  Alias for `show_classes`.

- sample_label_size:

  Text size for sample labels.

- class_label_size:

  Text size for class labels.

- point_size:

  Sample point size.

- point_color:

  Constant sample point color used when `color_by` is `NULL`.

- point_alpha:

  Sample point alpha.

- color_by:

  Optional column name used to map sample point color.

## Value

A `ggplot` object.
