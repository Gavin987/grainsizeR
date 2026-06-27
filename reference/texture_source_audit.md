# Inspect the texture source audit registry

`texture_source_audit()` returns a source-audit registry for planned
texture and particle-size systems. It is not a texture polygon dataset
and does not contain polygon coordinates, class vertices, or class
tables.

## Usage

``` r
texture_source_audit()
```

## Value

A tibble describing source-audit status for texture and particle-size
systems.

## Details

`primary_source_status = "needs_verification"` means that candidate
sources have not yet been reviewed as package-ready primary
documentation. Future built-in polygon datasets should be reconstructed
from original official or academic sources, cited, reviewed, and tested
before implementation.
