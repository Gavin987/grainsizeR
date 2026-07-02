# Compatibility alias for texture ternary plots

`plot_texture_triangle()` is retained as a compatibility alias for
[`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md).
Both functions create texture ternary plots and return ggplot objects
with equivalent behavior. Sample labels are hidden by default; use
`show_sample_labels = TRUE` to draw them. Point appearance can be
adjusted with `point_size`, `point_color`, and `point_alpha`, or mapped
to a summarized input column with `color_by`.

## Usage

``` r
plot_texture_triangle(...)
```

## Arguments

- ...:

  Arguments forwarded to
  [`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md).

## Value

See
[`plot_texture_ternary()`](https://Gavin987.github.io/grainsizeR/reference/plot_texture_ternary.md).
