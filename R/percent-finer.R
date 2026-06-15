thresholds_to_um <- function(sizes, size_unit) {
  size_unit <- match.arg(size_unit, c("um", "mm", "phi"))

  if (!is.numeric(sizes) || anyNA(sizes)) {
    stop("`sizes` must be a numeric vector without missing values.", call. = FALSE)
  }

  if (size_unit != "phi" && any(sizes <= 0)) {
    stop("`sizes` must contain positive grain-size thresholds.", call. = FALSE)
  }

  if (size_unit == "um") {
    sizes
  } else if (size_unit == "mm") {
    mm_to_um(sizes)
  } else {
    phi_to_um(sizes)
  }
}

percent_finer_scale_values <- function(curve, scale) {
  switch(
    scale,
    phi = curve$boundary_phi,
    log_um = log10(curve$boundary_um),
    linear_um = curve$boundary_um
  )
}

threshold_scale_values <- function(threshold_um, scale) {
  switch(
    scale,
    phi = um_to_phi(threshold_um),
    log_um = log10(threshold_um),
    linear_um = threshold_um
  )
}

percent_finer_one_sample <- function(curve, threshold_um, scale, extrapolate) {
  sample_id <- curve$sample_id[1]
  curve_scale <- percent_finer_scale_values(curve, scale)
  threshold_scale <- threshold_scale_values(threshold_um, scale)
  observed_min <- min(curve_scale)
  observed_max <- max(curve_scale)
  extrapolated <- threshold_scale < observed_min | threshold_scale > observed_max

  if (any(extrapolated) && extrapolate == "error") {
    stop(
      "Requested thresholds for sample `",
      sample_id,
      "` fall outside the finite boundary size range. Use ",
      "`extrapolate = \"warn_linear\"` to extrapolate.",
      call. = FALSE
    )
  }

  if (any(extrapolated) && extrapolate == "warn_linear") {
    warning(
      "Requested thresholds for sample `",
      sample_id,
      "` fall outside the finite boundary size range; linearly extrapolating.",
      call. = FALSE
    )
  }

  percent_finer <- linear_interpolate(
    x = curve_scale,
    y = curve$percent_finer,
    xout = threshold_scale,
    extrapolate = extrapolate
  )

  matches <- match(threshold_um, curve$boundary_um)
  exact <- !is.na(matches)
  percent_finer[exact] <- curve$percent_finer[matches[exact]]

  tibble::tibble(
    sample_id = sample_id,
    threshold_um = threshold_um,
    threshold_mm = um_to_mm(threshold_um),
    threshold_phi = um_to_phi(threshold_um),
    percent_finer = percent_finer,
    percent_coarser = 100 - percent_finer,
    interpolation_scale = scale,
    extrapolated = extrapolated
  )
}

#' Calculate percent finer than grain-size thresholds
#'
#' `gs_percent_finer()` returns the cumulative percent finer than one or more
#' requested grain-size thresholds for each sample. Values are taken exactly
#' from finite boundaries when thresholds match them, otherwise they are
#' interpolated on the selected scale.
#'
#' @param x A valid `gsd_tbl` object.
#' @param sizes Numeric vector of grain-size thresholds.
#' @param size_unit Unit for `sizes`. Supported values are `"um"`, `"mm"`, and
#'   `"phi"`.
#' @param scale Interpolation scale. `"phi"` interpolates in phi units,
#'   `"log_um"` interpolates in log10 micrometers, and `"linear_um"`
#'   interpolates directly in micrometers.
#' @param extrapolate Behavior when a requested threshold falls outside the
#'   observed finite boundary size range. `"error"` throws an error, and
#'   `"warn_linear"` warns and linearly extrapolates on the selected scale.
#'
#' @return A tibble with one row per sample and requested threshold.
#' @export
gs_percent_finer <- function(x,
                             sizes,
                             size_unit = "um",
                             scale = c("phi", "log_um", "linear_um"),
                             extrapolate = c("error", "warn_linear")) {
  validate_gsd_tbl(x)
  scale <- match.arg(scale)
  extrapolate <- match.arg(extrapolate)
  threshold_um <- thresholds_to_um(sizes, size_unit)

  curve <- gs_cumulative(x)
  split_curve <- split(curve, curve$sample_id, drop = TRUE)
  out <- lapply(
    split_curve,
    percent_finer_one_sample,
    threshold_um = threshold_um,
    scale = scale,
    extrapolate = extrapolate
  )

  out <- do.call(rbind, unname(out))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
