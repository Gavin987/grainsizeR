# Plot samples on a ternary diagram

`plot_trigon()` is a compatibility plotting name for texture ternary
plots. Prefer
[`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md)
in new code and prose. Optional user-supplied polygons can be drawn as
overlays. For USDA major texture classes, the function draws internal
rule-derived class boundaries without depending on external texture
plotting packages.

## Usage

``` r
plot_trigon(
  x,
  scheme = c("gradistat", "usda_tt", "isss", "uk_ssew"),
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
  class_label_size = 2.3
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
  [`gs_fractions_wide()`](https://Gavin987.github.io/grainsizeR/reference/gs_fractions_wide.md).

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
  [`classify_texture()`](https://Gavin987.github.io/grainsizeR/reference/classify_texture.md)?

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

## Value

A `ggplot` object.
