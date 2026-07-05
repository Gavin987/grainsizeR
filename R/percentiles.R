percentile_scale_values <- function(curve, scale) {
  switch(
    scale,
    phi = curve$boundary_phi,
    log_um = log10(curve$boundary_um),
    linear_um = curve$boundary_um
  )
}

scale_values_to_um <- function(value, scale) {
  switch(
    scale,
    phi = phi_to_um(value),
    log_um = 10^value,
    linear_um = value
  )
}

#' Linearly interpolate a cumulative curve, breaking ties deterministically
#'
#' Grain-size cumulative curves can contain runs of classes with zero
#' retained mass (e.g. several consecutive sieve apertures with nothing
#' caught between them), which produce exact ties in `x` (multiple distinct
#' boundaries sharing the same cumulative value). Ordering by `x` alone
#' leaves the relative order of tied rows undefined (dependent on
#' incidental input row order), so a target that falls between two tied
#' plateaus can bracket against either edge of each plateau depending on
#' that incidental order.
#'
#' `tie_break_um` resolves this deterministically: within any run of tied
#' `x` values, rows are additionally sorted by ascending physical size
#' (`tie_break_um`, always finite/finest-first regardless of which scale
#' `x`/`y` are expressed on). This places the *finest* member of a tied
#' plateau first (available as the bracket partner for a target
#' approaching from a smaller `x`) and the *coarsest* member last
#' (available as the bracket partner for a target approaching from a
#' larger `x`) - i.e. every interpolation uses the narrowest possible
#' bracket immediately adjacent to the plateau boundary where the
#' cumulative curve actually changes value, rather than an arbitrary edge
#' of a multi-row plateau.
#'
#' This mirrors the effect (not the code) of G2Sd::granstat()'s internal
#' `.percentile()`, which resolves the same situation with an explicit
#' filter chain that keeps, among tied rows, the one nearest each side's
#' transition (`filter(phi == max(phi))` / `filter(phi == min(phi))` after
#' filtering to the candidate side) - see `G2Sd:::.percentile` for its
#' independent implementation. This is an independent, from-scratch
#' implementation for grainsizeR, not a translation of G2Sd's code.
#'
#' @param x,y Numeric vectors giving the coordinates of the points to
#'   interpolate.
#' @param xout Numeric vector of values at which to interpolate.
#' @param extrapolate Behavior outside the observed range of `x`. `"error"`
#'   is enforced by callers before reaching this function; `"warn_linear"`
#'   linearly extrapolates using the two nearest points on the relevant
#'   side.
#' @param tie_break_um Physical size in micrometers for each `(x, y)` pair,
#'   used only to break ties in `x`. Has no effect when `x` has no
#'   duplicated values.
#' @noRd
linear_interpolate <- function(x, y, xout, extrapolate, tie_break_um) {
  ord <- order(x, tie_break_um)
  x <- x[ord]
  y <- y[ord]

  if (length(unique(x)) < 2) {
    stop("At least two distinct boundary values are required for interpolation.", call. = FALSE)
  }

  interpolated <- stats::approx(
    x = x,
    y = y,
    xout = xout,
    rule = 1,
    ties = "ordered"
  )$y

  outside_lower <- xout < min(x)
  outside_upper <- xout > max(x)

  if (extrapolate == "warn_linear" && any(outside_lower)) {
    slope <- (y[2] - y[1]) / (x[2] - x[1])
    interpolated[outside_lower] <- y[1] + slope * (xout[outside_lower] - x[1])
  }

  if (extrapolate == "warn_linear" && any(outside_upper)) {
    n <- length(x)
    slope <- (y[n] - y[n - 1]) / (x[n] - x[n - 1])
    interpolated[outside_upper] <- y[n] + slope * (xout[outside_upper] - x[n])
  }

  interpolated
}

# Ties in `curve$percent_finer` (from consecutive zero-retained classes)
# are broken deterministically via `tie_break_um`; see linear_interpolate().
percentile_one_sample <- function(curve, probs, scale, extrapolate) {
  sample_id <- curve$sample_id[1]
  scale_value <- percentile_scale_values(curve, scale)
  observed_min <- min(curve$percent_finer)
  observed_max <- max(curve$percent_finer)
  extrapolated <- probs < observed_min | probs > observed_max

  if (any(extrapolated) && extrapolate == "error") {
    stop(
      "Requested percentiles for sample `",
      sample_id,
      "` fall outside the finite boundary curve range [",
      format(observed_min, digits = 8),
      ", ",
      format(observed_max, digits = 8),
      "]. Use `extrapolate = \"warn_linear\"` to extrapolate.",
      call. = FALSE
    )
  }

  if (any(extrapolated) && extrapolate == "warn_linear") {
    warning(
      "Requested percentiles for sample `",
      sample_id,
      "` fall outside the finite boundary curve range; linearly extrapolating.",
      call. = FALSE
    )
  }

  interpolated_scale <- linear_interpolate(
    x = curve$percent_finer,
    y = scale_value,
    xout = probs,
    extrapolate = extrapolate,
    tie_break_um = curve$boundary_um
  )

  grain_size_um <- scale_values_to_um(interpolated_scale, scale)

  tibble::tibble(
    sample_id = sample_id,
    percentile = probs,
    grain_size_um = grain_size_um,
    grain_size_mm = um_to_mm(grain_size_um),
    grain_size_phi = um_to_phi(grain_size_um),
    interpolation_scale = scale,
    extrapolated = extrapolated
  )
}

#' Calculate grain-size percentiles
#'
#' `gs_d_values()` estimates `D_p`, the grain size at which `p` percent of a
#' sample is finer. Interpolation is based on finite class boundaries from
#' `gs_cumulative()`, not class midpoints.
#'
#' Some samples contain a run of consecutive classes with zero retained
#' mass (e.g. several sieve apertures with nothing caught between them),
#' which produces an exact tie in cumulative percent finer across those
#' boundaries. When a requested percentile falls between such a tied
#' plateau and an adjacent distinct value, `gs_d_values()` resolves the tie
#' deterministically: it brackets against the member of the tied plateau
#' nearest the real transition (the finest boundary of a plateau being
#' approached from below, or the coarsest boundary of a plateau being
#' approached from above), rather than depending on incidental input row
#' order. This is a fixed, documented rule, not an implementation detail
#' that may vary between calls or package versions.
#'
#' @param x A valid `gsd_tbl` object.
#' @param probs Numeric vector of percentiles on the 0-100 scale.
#' @param interpolation_scale Interpolation scale. `"phi"` interpolates in phi units,
#'   `"log_um"` interpolates in log10 micrometers, and `"linear_um"`
#'   interpolates directly in micrometers.
#' @param output_unit Preferred reporting unit. The returned table always
#'   includes micrometer, millimeter, and phi columns.
#' @param extrapolate Behavior when a requested percentile falls outside the
#'   observed finite boundary curve. `"error"` throws an error, and
#'   `"warn_linear"` warns and linearly extrapolates on the selected scale.
#' @param scale Compatibility alias for `interpolation_scale`.
#'
#' @return A tibble with one row per sample and requested percentile.
#' @export
gs_d_values <- function(x,
                        probs = c(5, 10, 16, 25, 30, 50, 60, 75, 84, 90, 95),
                        interpolation_scale = c("phi", "log_um", "linear_um"),
                        output_unit = c("um", "mm", "phi"),
                        extrapolate = c("error", "warn_linear"),
                        scale = NULL) {
  validate_gsd_tbl(x)
  if (!is.null(scale)) {
    interpolation_scale <- scale
  }
  interpolation_scale <- match.arg(interpolation_scale)
  output_unit <- match.arg(output_unit)
  extrapolate <- match.arg(extrapolate)

  if (!is.numeric(probs) || anyNA(probs)) {
    stop("`probs` must be a numeric vector without missing values.", call. = FALSE)
  }

  if (any(probs < 0 | probs > 100)) {
    stop("`probs` must contain values on the 0-100 scale.", call. = FALSE)
  }

  curve <- gs_cumulative(x)
  split_curve <- split(curve, curve$sample_id, drop = TRUE)
  percentiles <- lapply(
    split_curve,
    percentile_one_sample,
    probs = probs,
    scale = interpolation_scale,
    extrapolate = extrapolate
  )

  out <- do.call(rbind, unname(percentiles))
  rownames(out) <- NULL
  out <- tibble::as_tibble(out)

  if (output_unit == "mm") {
    out <- out[c(
      "sample_id",
      "percentile",
      "grain_size_mm",
      "grain_size_um",
      "grain_size_phi",
      "interpolation_scale",
      "extrapolated"
    )]
  } else if (output_unit == "phi") {
    out <- out[c(
      "sample_id",
      "percentile",
      "grain_size_phi",
      "grain_size_um",
      "grain_size_mm",
      "interpolation_scale",
      "extrapolated"
    )]
  }

  out
}

#' Calculate grain-size percentiles
#'
#' `gs_percentile()` is a compatibility alias for `gs_d_values()`, including
#' its deterministic handling of ties from zero-retained classes (see
#' `gs_d_values()` for details).
#'
#' @inheritParams gs_d_values
#'
#' @return A tibble with one row per sample and requested percentile.
#' @export
gs_percentile <- function(x,
                          probs = c(5, 10, 16, 25, 30, 50, 60, 75, 84, 90, 95),
                          interpolation_scale = c("phi", "log_um", "linear_um"),
                          output_unit = c("um", "mm", "phi"),
                          extrapolate = c("error", "warn_linear"),
                          scale = NULL) {
  gs_d_values(
    x = x,
    probs = probs,
    interpolation_scale = interpolation_scale,
    output_unit = output_unit,
    extrapolate = extrapolate,
    scale = scale
  )
}
