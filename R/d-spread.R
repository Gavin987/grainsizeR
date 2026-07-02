d_spread_values <- function(percentiles, scale) {
  sample_ids <- unique(percentiles$sample_id)
  percentile_groups <- split(percentiles, percentiles$sample_id, drop = TRUE)
  rows <- lapply(sample_ids, function(sample_id) {
    one <- percentile_groups[[sample_id]]
    values <- if (scale == "um") one$grain_size_um else one$grain_size_mm
    names(values) <- paste0("D", one$percentile)
    um_values <- one$grain_size_um
    names(um_values) <- paste0("D", one$percentile)

    ratio_90_10 <- values[["D90"]] / values[["D10"]]
    ratio_75_25 <- values[["D75"]] / values[["D25"]]

    tibble::tibble(
      sample_id = sample_id,
      D10 = values[["D10"]],
      D25 = values[["D25"]],
      D50 = values[["D50"]],
      D75 = values[["D75"]],
      D90 = values[["D90"]],
      d_value_unit = scale,
      D90_D10_ratio = ratio_90_10,
      D90_minus_D10 = values[["D90"]] - values[["D10"]],
      D75_D25_ratio = ratio_75_25,
      D75_minus_D25 = values[["D75"]] - values[["D25"]],
      D90_D10_log_ratio = log10(um_values[["D90"]] / um_values[["D10"]]),
      D75_D25_log_ratio = log10(um_values[["D75"]] / um_values[["D25"]]),
      any_extrapolated = any(one$extrapolated)
    )
  })

  out <- do.call(rbind, unname(rows))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Calculate GRADISTAT-style D-spread descriptors
#'
#' `gs_d_spread()` calculates D-value spread descriptors commonly reported in
#' GRADISTAT-style grain-size summaries. It reuses `gs_d_values()` for D10,
#' D25, D50, D75, and D90, then derives D90/D10, D90 - D10, D75/D25, and
#' D75 - D25.
#'
#' Ratios and differences are metric descriptors. `scale = "um"` reports
#' D-values and differences in micrometers, while `scale = "mm"` reports them
#' in millimeters. `scale = "phi"` is not supported because phi differences are
#' not the same parameter as metric D-value spread differences. Optional log
#' ratio columns are calculated from positive metric D-values.
#'
#' Open-tail behavior follows `gs_d_values()`: by default unresolved requested
#' percentiles throw an error, and `extrapolate = "warn_linear"` explicitly
#' allows linear extrapolation and marks affected samples with
#' `any_extrapolated = TRUE`.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scale Metric reporting scale for D-values and differences. Supported
#'   values are `"um"` and `"mm"`.
#' @param interpolation_scale Interpolation scale passed to `gs_d_values()`.
#' @param extrapolate Extrapolation behavior passed to `gs_d_values()`.
#'
#' @return A tibble with one row per sample and D-spread descriptor columns.
#' @export
#'
#' @examples
#' gsd <- as_gsd_tbl(
#'   data.frame(
#'     sample = rep("A", 5),
#'     size_mm = c(2, 1, 0.5, 0.25, 0.125),
#'     retained = c(5, 15, 35, 30, 15)
#'   ),
#'   sample,
#'   size_mm,
#'   retained,
#'   value_type = "percent"
#' )
#'
#' gs_d_spread(gsd, extrapolate = "warn_linear")
gs_d_spread <- function(x,
                        scale = c("um", "mm"),
                        interpolation_scale = c("phi", "log_um", "linear_um"),
                        extrapolate = c("error", "warn_linear")) {
  validate_gsd_tbl(x)
  scale <- match.arg(scale)
  interpolation_scale <- match.arg(interpolation_scale)
  extrapolate <- match.arg(extrapolate)

  percentiles <- gs_d_values(
    x,
    probs = c(10, 25, 50, 75, 90),
    interpolation_scale = interpolation_scale,
    output_unit = "um",
    extrapolate = extrapolate
  )

  d_spread_values(percentiles, scale = scale)
}
