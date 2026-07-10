# Create an empty texture polygon reconstruction template

`texture_polygon_reconstruction_template()` returns an empty tibble with
the detailed developer-oriented schema used for future official texture
polygon reconstruction work. It is more detailed than
[`texture_polygon_template()`](https://gavin987.github.io/grainsizeR/reference/texture_polygon_template.md)
because it records source, review, reconstruction, validation, and
comparison metadata.

## Usage

``` r
texture_polygon_reconstruction_template()
```

## Value

An empty tibble with reconstruction-template columns.

## Details

The returned object is a template only. It is not package polygon data
and contains no real polygon coordinates.
