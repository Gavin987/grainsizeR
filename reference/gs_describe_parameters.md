# Attach GRADISTAT-style parameter descriptions

`gs_describe_parameters()` appends descriptive terms for mean grain
size, sorting, skewness, and kurtosis to tables returned by
[`gs_folk_ward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folk_ward.md),
[`gs_folkward()`](https://Gavin987.github.io/grainsizeR/reference/gs_folkward.md),
[`gs_moments()`](https://Gavin987.github.io/grainsizeR/reference/gs_moments.md),
or
[`gs_parameters()`](https://Gavin987.github.io/grainsizeR/reference/gs_parameters.md),
or to any data frame with recognized statistic columns.

## Usage

``` r
gs_describe_parameters(
  x,
  method = c("auto", "folk_ward", "logarithmic_moments")
)
```

## Arguments

- x:

  A data frame containing recognized grain-size statistic columns.

- method:

  Descriptor method. `"auto"` detects recognized columns, `"folk_ward"`
  uses Folk and Ward columns, and `"logarithmic_moments"` uses moment
  columns in phi units.

## Value

The input data frame with descriptor columns appended.

## Details

Supported methods are Folk and Ward graphical statistics and logarithmic
moment statistics in phi units. The output is deterministic and
conservative: rows with missing required values are marked rather than
silently described. These descriptions support a GRADISTAT-style
printout layer, but they do not implement full GRADISTAT sediment naming
or texture classification.
