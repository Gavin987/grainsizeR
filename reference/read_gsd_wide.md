# Read wide-format grain-size data from a CSV file

`read_gsd_wide()` reads a table where grain-size classes are stored in
rows and sample identifiers are stored in columns. Values are retained
proportions, retained percentages, or weights.

## Usage

``` r
read_gsd_wide(
  file,
  size_col = 1,
  size_unit = "auto",
  value_type = "percent",
  measurement_method = NA_character_
)
```

## Arguments

- file:

  Path to a CSV file.

- size_col:

  Column containing grain-size class labels or thresholds. This can be a
  one-based column index or a column name.

- size_unit:

  Unit for `size_col`. Supported values are `"auto"`, `"mm"`, `"um"`,
  and `"phi"`. `"auto"` treats finite positive values greater than or
  equal to 1000 as micrometres and otherwise treats values as
  millimetres. Explicit `"mm"` and `"um"` values override detection.

- value_type:

  Scale for sample values. Supported values are `"proportion"`,
  `"percent"`, and `"weight"`.

- measurement_method:

  Measurement method to store in the output. A single string is recycled
  to all rows.

## Value

A `gsd_tbl` tibble with canonical columns including `sample_id`,
`bin_id`, `raw_size_um`, `size_lower_um`, `size_upper_um`,
`retained_percent`, `cum_finer_percent`, `cum_coarser_percent`,
`is_open_lower`, `is_open_upper`, and `measurement_method`.

## Details

Numeric size labels such as `"2"` and `"0.0625"` are interpreted as
class thresholds. Terminal fine labels such as `"<0.0625"` in a strict
Wentworth-style example are parsed as the numeric threshold while still
producing an open-ended fine class in the returned `gsd_tbl`. A size
label of `"0"` is treated as a pan or lower open-ended row and imported
with the package's 1 um lower-tail marker.
