# Describe grain-size terms

`gs_size_terms()` assigns concise modified Udden-Wentworth-style size
terms to numeric grain sizes. The helper accepts phi, millimeter, or
micrometer input and uses the same class labels as
[`describe_mean_size_phi()`](https://gavin987.github.io/grainsizeR/reference/describe_mean_size_phi.md).

## Usage

``` r
gs_size_terms(x, unit = c("phi", "mm", "um"))
```

## Arguments

- x:

  Numeric grain sizes.

- unit:

  Unit of `x`. Supported values are `"phi"`, `"mm"`, and `"um"`.

## Value

A character vector of size terms.

## Details

The terms are useful for GRADISTAT-style printout layers, but they are
not full GRADISTAT sediment names or texture classifications.
