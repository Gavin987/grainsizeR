# Read grain-size data from a delimited text file

`read_gsd()` reads a comma-separated file and converts a long- or
wide-format table into a `gsd_tbl`.

## Usage

``` r
read_gsd(
  file,
  sample_col,
  size_col,
  value_col,
  size_unit = "auto",
  value_type = "proportion",
  measurement_method = NA_character_,
  format = c("long", "wide")
)
```

## Arguments

- file:

  Path to a CSV file.

- sample_col:

  Column containing sample identifiers. If omitted for long-format
  input, `read_gsd()` uses `"sample"` when that column exists.

- size_col:

  Column containing grain-size class labels or thresholds. If omitted
  for long-format input, `read_gsd()` uses `"size"` when that column
  exists.

- value_col:

  Column containing retained proportions, retained percentages, or
  weights. If omitted for long-format input, `read_gsd()` uses
  `"proportion"` when that column exists.

- size_unit:

  Unit for `size_col`. Supported values are `"auto"`, `"mm"`, `"um"`,
  and `"phi"`. `"auto"` treats finite positive values greater than or
  equal to 1000 as micrometres and otherwise treats values as
  millimetres. Explicit `"mm"` and `"um"` values override detection.

- value_type:

  Scale for `value_col`. Supported values are `"proportion"`,
  `"percent"`, and `"weight"`. For `format = "wide"`, omitted
  `value_type` uses the
  [`read_gsd_wide()`](https://Gavin987.github.io/grainsizeR/reference/read_gsd_wide.md)
  default.

- measurement_method:

  Measurement method to store in the output.

- format:

  Input table format. `"long"` reads one row per sample and grain-size
  class. `"wide"` reads grain-size classes from rows and sample
  identifiers from columns.

## Value

A `gsd_tbl` tibble with canonical columns including `sample_id`,
`bin_id`, `raw_size_um`, `size_lower_um`, `size_upper_um`,
`retained_percent`, `cum_finer_percent`, `cum_coarser_percent`,
`is_open_lower`, `is_open_upper`, and `measurement_method`.
