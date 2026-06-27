# Report GRADISTAT-inspired quality flags

`gs_quality_flags()` returns lightweight advisory flags for conditions
that affect GRADISTAT-style grain-size interpretation. It currently
reports sediment-loss status when the user supplies loss percentages,
open fine-tail status from `gsd_tbl` class structure, and advisory
fine-pan fraction thresholds.

## Usage

``` r
gs_quality_flags(
  x,
  sediment_loss_percent = NULL,
  sediment_loss_warning_percent = 2,
  fine_pan_info_percent = 1,
  fine_pan_warning_percent = 5
)
```

## Arguments

- x:

  A valid `gsd_tbl` object.

- sediment_loss_percent:

  Optional sediment-loss percentages. Supply a named numeric vector
  keyed by `sample_id`, or an unnamed scalar for a single-sample object.

- sediment_loss_warning_percent:

  Advisory sediment-loss warning threshold. The default is 2 percent.

- fine_pan_info_percent:

  Advisory lower threshold for noting a retained open fine pan fraction.

- fine_pan_warning_percent:

  Advisory warning threshold for a retained open fine pan fraction.

## Value

A tibble with quality flag rows by sample.

## Details

The function does not invent mass-loss information. If sediment-loss
values are not supplied, the sediment-loss flag is returned as
`"not_evaluated"`. Open-tail flags are advisory and do not replace
method-specific open-tail handling in D-values, fractions, moments, or
other calculations.
