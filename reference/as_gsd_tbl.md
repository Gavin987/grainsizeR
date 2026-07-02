# Convert long-format grain-size data to a `gsd_tbl`

`as_gsd_tbl()` accepts one row per sample and grain-size class. Rows may
be ragged: different samples can have different size labels and
different numbers of classes. Within each sample, size labels are sorted
internally from coarse to fine before class boundaries are constructed.

## Usage

``` r
as_gsd_tbl(
  x,
  sample_col,
  size_col,
  value_col,
  size_unit = "auto",
  value_type = "proportion",
  measurement_method = NA_character_
)
```

## Arguments

- x:

  A data frame containing long-format grain-size data.

- sample_col:

  Column containing sample identifiers.

- size_col:

  Column containing grain-size class labels or thresholds.

- value_col:

  Column containing retained proportions, retained percentages, or
  weights.

- size_unit:

  Unit for `size_col`. Supported values are `"auto"`, `"mm"`, `"um"`,
  and `"phi"`. `"auto"` treats finite positive values greater than or
  equal to 1000 as micrometres and otherwise treats values as
  millimetres. Explicit `"mm"` and `"um"` values override detection.

- value_type:

  Scale for `value_col`. Supported values are `"proportion"`,
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

For sorted size labels `s1 > s2 > ... > sn`, bins are interpreted as
`> s1`, `s2` to `s1`, ..., and `< s(n - 1)`. The final row's numeric
size label is preserved in `raw_size_um`, but it is not used as the true
lower boundary of the terminal fine class. A size label of `0`, commonly
used for a pan or lower open-ended class, is imported as the package's 1
um lower-tail marker rather than as an observed zero-size boundary.
