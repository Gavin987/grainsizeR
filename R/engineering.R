engineering_one_sample <- function(sample_id, percentiles, fine_content, interpolation_scale, fine_threshold_um) {
  p <- percentiles[percentiles$sample_id == sample_id, ]
  d <- stats::setNames(p$grain_size_um, paste0("D", p$percentile, "_um"))
  fine <- fine_content$percent_finer[fine_content$sample_id == sample_id]

  D10 <- d[["D10_um"]]
  D25 <- d[["D25_um"]]
  D30 <- d[["D30_um"]]
  D50 <- d[["D50_um"]]
  D60 <- d[["D60_um"]]
  D75 <- d[["D75_um"]]

  tibble::tibble(
    sample_id = sample_id,
    D10_um = D10,
    D25_um = D25,
    D30_um = D30,
    D50_um = D50,
    D60_um = D60,
    D75_um = D75,
    Cu = D60 / D10,
    Cc = D30^2 / (D10 * D60),
    So_trask = sqrt(D75 / D25),
    Sk_trask = D25 * D75 / D50^2,
    fine_content_percent = fine,
    fine_threshold_um = fine_threshold_um,
    fine_equivalent = fine / log10(D75 / D25),
    interpolation_scale = interpolation_scale
  )
}

#' Calculate additional grain-size indices
#'
#' `gs_grain_size_indices()` calculates additional grain-size indices from
#' boundary-based D-value interpolation and a fine-content threshold. Returned
#' indices include coefficient of uniformity (`Cu`), coefficient of curvature
#' (`Cc`), Trask sorting, Trask skewness, fine content, and fine equivalent.
#'
#' @param x A valid `gsd_tbl` object.
#' @param fine_threshold_um Fine-content threshold in micrometers.
#' @param interpolation_scale Interpolation scale passed to `gs_d_values()`
#'   and `gs_percent_finer()`.
#' @param extrapolate Extrapolation behavior passed to `gs_d_values()` and
#'   `gs_percent_finer()`.
#'
#' @return A tibble with one row per sample and grain-size indices.
#' @export
gs_grain_size_indices <- function(x,
                                  fine_threshold_um = 62.5,
                                  interpolation_scale = "phi",
                                  extrapolate = "error") {
  validate_gsd_tbl(x)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  percentiles <- gs_d_values(
    x,
    probs = c(10, 25, 30, 50, 60, 75),
    interpolation_scale = interpolation_scale,
    output_unit = "um",
    extrapolate = extrapolate
  )
  fine_content <- gs_percent_finer(
    x,
    sizes = fine_threshold_um,
    size_unit = "um",
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate
  )

  sample_ids <- unique(percentiles$sample_id)
  out <- lapply(
    sample_ids,
    engineering_one_sample,
    percentiles = percentiles,
    fine_content = fine_content,
    interpolation_scale = interpolation_scale,
    fine_threshold_um = fine_threshold_um
  )

  out <- do.call(rbind, unname(out))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Calculate additional grain-size indices
#'
#' `gs_engineering()` is a compatibility alias for
#' `gs_grain_size_indices()`. It returns grain-size index values only; it does
#' not implement complete civil-engineering classification systems such as
#' AASHTO or USCS.
#'
#' @param ... Arguments forwarded to `gs_grain_size_indices()`.
#'
#' @return A tibble with one row per sample and grain-size indices.
#' @export
gs_engineering <- function(...) {
  gs_grain_size_indices(...)
}
