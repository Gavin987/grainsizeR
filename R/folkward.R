folkward_one_sample <- function(sample_id, percentiles, interpolation_scale, include_descriptions) {
  p <- percentiles[percentiles$sample_id == sample_id, ]
  d_um <- stats::setNames(p$grain_size_um, paste0("D", p$percentile, "_um"))
  d_phi <- stats::setNames(p$grain_size_phi, paste0("D", p$percentile, "_phi"))

  D5_phi <- d_phi[["D5_phi"]]
  D16_phi <- d_phi[["D16_phi"]]
  D25_phi <- d_phi[["D25_phi"]]
  D50_phi <- d_phi[["D50_phi"]]
  D75_phi <- d_phi[["D75_phi"]]
  D84_phi <- d_phi[["D84_phi"]]
  D95_phi <- d_phi[["D95_phi"]]

  mean_fw_phi <- (D16_phi + D50_phi + D84_phi) / 3
  sorting_fw_phi <- (D16_phi - D84_phi) / 4 + (D5_phi - D95_phi) / 6.6
  skewness_fw <- ((D16_phi + D84_phi - 2 * D50_phi) / (2 * (D16_phi - D84_phi))) +
    ((D5_phi + D95_phi - 2 * D50_phi) / (2 * (D5_phi - D95_phi)))
  kurtosis_fw <- (D5_phi - D95_phi) / (2.44 * (D25_phi - D75_phi))

  out <- tibble::tibble(
    sample_id = sample_id,
    D5_um = d_um[["D5_um"]],
    D16_um = d_um[["D16_um"]],
    D25_um = d_um[["D25_um"]],
    D50_um = d_um[["D50_um"]],
    D75_um = d_um[["D75_um"]],
    D84_um = d_um[["D84_um"]],
    D95_um = d_um[["D95_um"]],
    D5_phi = D5_phi,
    D16_phi = D16_phi,
    D25_phi = D25_phi,
    D50_phi = D50_phi,
    D75_phi = D75_phi,
    D84_phi = D84_phi,
    D95_phi = D95_phi,
    mean_fw_phi = mean_fw_phi,
    mean_fw_um = phi_to_um(mean_fw_phi),
    sorting_fw_phi = sorting_fw_phi,
    skewness_fw = skewness_fw,
    kurtosis_fw = kurtosis_fw,
    interpolation_scale = interpolation_scale,
    any_extrapolated = any(p$extrapolated)
  )

  if (include_descriptions) {
    out$mean_size_class <- describe_mean_size_phi(out$mean_fw_phi)
    out$sorting_class <- describe_sorting_fw(out$sorting_fw_phi)
    out$skewness_class <- describe_skewness_fw(out$skewness_fw)
    out$kurtosis_class <- describe_kurtosis_fw(out$kurtosis_fw)
  }

  out
}

#' Calculate Folk and Ward graphical grain-size statistics
#'
#' `gs_folk_ward()` calculates Folk and Ward graphical statistics from
#' boundary-interpolated grain-size percentiles. Percentiles follow the package
#' convention where `D_p` is the grain size at which `p` percent of the sample
#' is finer.
#'
#' @param x A valid `gsd_tbl` object.
#' @param interpolation_scale Interpolation scale passed to `gs_d_values()`.
#' @param extrapolate Extrapolation behavior passed to `gs_d_values()`.
#' @param include_descriptions Should descriptive Folk and Ward class labels be
#'   included?
#'
#' @return A tibble with one row per sample and Folk and Ward graphical
#'   statistics.
#' @export
gs_folk_ward <- function(x,
                         interpolation_scale = "phi",
                         extrapolate = c("error", "warn_linear"),
                         include_descriptions = TRUE) {
  validate_gsd_tbl(x)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  extrapolate <- match.arg(extrapolate)

  percentiles <- gs_d_values(
    x,
    probs = c(5, 16, 25, 50, 75, 84, 95),
    interpolation_scale = interpolation_scale,
    output_unit = "um",
    extrapolate = extrapolate
  )

  sample_ids <- unique(percentiles$sample_id)
  out <- lapply(
    sample_ids,
    folkward_one_sample,
    percentiles = percentiles,
    interpolation_scale = interpolation_scale,
    include_descriptions = include_descriptions
  )

  out <- do.call(rbind, unname(out))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Calculate Folk and Ward graphical grain-size statistics
#'
#' `gs_folkward()` is a compatibility alias for `gs_folk_ward()`.
#'
#' @param ... Arguments forwarded to `gs_folk_ward()`.
#'
#' @return A tibble with one row per sample and Folk and Ward graphical
#'   statistics.
#' @export
gs_folkward <- function(...) {
  gs_folk_ward(...)
}
