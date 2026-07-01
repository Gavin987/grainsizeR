scheme_components <- function(scheme) {
  scheme <- .validate_fraction_scheme(scheme)
  schemes <- gs_fraction_schemes()
  out <- schemes[schemes$scheme == scheme, ]
  out
}

required_fraction_thresholds <- function(components) {
  sort(unique(c(
    components$lower_mm[is.finite(components$lower_mm) & components$lower_mm > 0],
    components$upper_mm[is.finite(components$upper_mm) & components$upper_mm > 0]
  )))
}

percent_finer_lookup <- function(x, thresholds_mm, interpolation_scale, extrapolate, unresolved) {
  sample_ids <- unique(as.character(x$sample_id))
  normalized_x <- .gsd_tbl_with_normalized_mm_sizes(x)

  if (length(thresholds_mm) == 0) {
    return(tibble::tibble(
      sample_id = character(),
      threshold_mm = numeric(),
      threshold_um = numeric(),
      percent_finer = numeric(),
      resolved = logical()
    ))
  }

  rows <- list()
  row_id <- 1
  unresolved_seen <- FALSE
  for (sample_id in sample_ids) {
    sample_x <- normalized_x[normalized_x$sample_id == sample_id, ]
    curve <- gs_cumulative(sample_x)
    finite_mm <- curve$boundary_mm
    min_mm <- min(finite_mm)
    max_mm <- max(finite_mm)
    for (threshold in thresholds_mm) {
      if (threshold < min_mm) {
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_mm = threshold,
          threshold_um = mm_to_um(threshold),
          percent_finer = 0,
          resolved = TRUE
        )
      } else if (threshold > max_mm) {
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_mm = threshold,
          threshold_um = mm_to_um(threshold),
          percent_finer = 100,
          resolved = TRUE
        )
      } else {
        one <- tryCatch(
          gs_percent_finer(
            sample_x,
            sizes = threshold,
            size_unit = "mm",
            interpolation_scale = interpolation_scale,
            extrapolate = extrapolate
          ),
          error = function(err) NULL
        )
        if (is.null(one)) {
          unresolved_seen <- TRUE
          if (unresolved == "error") {
            stop("Required fraction thresholds could not be resolved.", call. = FALSE)
          }
          rows[[row_id]] <- tibble::tibble(
            sample_id = sample_id,
            threshold_mm = threshold,
            threshold_um = mm_to_um(threshold),
            percent_finer = NA_real_,
            resolved = FALSE
          )
        } else {
          rows[[row_id]] <- tibble::tibble(
            sample_id = sample_id,
            threshold_mm = one$threshold_mm,
            threshold_um = one$threshold_um,
            percent_finer = one$percent_finer,
            resolved = TRUE
          )
        }
      }
      row_id <- row_id + 1
    }
  }

  if (unresolved_seen) {
    warning(
      "Some required fraction thresholds could not be resolved; affected components are returned as NA.",
      call. = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

lookup_threshold <- function(lookup, sample_id, threshold) {
  row <- lookup[lookup$sample_id == sample_id & lookup$threshold_mm == threshold, ]
  if (nrow(row) == 0) {
    return(list(value = NA_real_, resolved = FALSE))
  }
  list(value = row$percent_finer[1], resolved = row$resolved[1])
}

component_percent <- function(component, lookup, sample_id) {
  lower <- component$lower_mm
  upper <- component$upper_mm

  lower_value <- 0
  upper_value <- 100
  lower_resolved <- TRUE
  upper_resolved <- TRUE

  if (lower > 0) {
    lower_lookup <- lookup_threshold(lookup, sample_id, lower)
    lower_value <- lower_lookup$value
    lower_resolved <- lower_lookup$resolved
  }

  if (is.finite(upper)) {
    upper_lookup <- lookup_threshold(lookup, sample_id, upper)
    upper_value <- upper_lookup$value
    upper_resolved <- upper_lookup$resolved
  }

  resolved <- lower_resolved && upper_resolved
  percent <- if (resolved) upper_value - lower_value else NA_real_

  list(percent = percent, resolved = resolved)
}

fractions_one_sample <- function(sample_id, components, lookup, scheme, normalize, interpolation_scale) {
  rows <- lapply(seq_len(nrow(components)), function(i) {
    comp_row <- components[i, ]
    fraction <- component_percent(comp_row, lookup, sample_id)
    tibble::tibble(
      sample_id = sample_id,
      scheme = scheme,
      component = comp_row$component,
      lower_mm = comp_row$lower_mm,
      upper_mm = comp_row$upper_mm,
      lower_um = comp_row$lower_um,
      upper_um = comp_row$upper_um,
      percent = fraction$percent,
      normalize = normalize,
      interpolation_scale = interpolation_scale,
      resolved = fraction$resolved
    )
  })

  out <- do.call(rbind, rows)

  if (normalize == "fine_earth") {
    gravel <- out$percent[out$component == "gravel"][1]
    denominator <- 100 - gravel
    out <- out[out$component != "gravel", ]
    if (is.na(denominator) || denominator <= 0) {
      out$percent <- NA_real_
      out$resolved <- FALSE
    } else {
      out$percent <- out$percent / denominator * 100
    }
  }

  out
}

#' Calculate grain-size fraction percentages
#'
#' `gs_fractions()` calculates sediment or soil fraction percentages using a
#' named built-in particle-size scheme. Schemes are treated as complete,
#' non-overlapping particle-size partitions. Fractions are calculated from
#' cumulative percent-finer values at scheme thresholds by calling
#' `gs_percent_finer()` for thresholds inside the observed finite size range.
#'
#' Scheme thresholds do not need to match observed grain-size boundaries. When
#' thresholds such as 0.002, 0.020, 0.050, 0.060, or 0.063 mm are bracketed by finite class
#' boundaries, percent-finer values are interpolated on the cumulative curve.
#' Fraction and texture functions automatically use the normalized particle-size
#' scale from `gsd_tbl`; users do not need to specify millimetres or
#' micrometres after import.
#' Thresholds above the largest observed finite boundary resolve to 100 percent
#' finer, and thresholds below the smallest observed finite boundary resolve to
#' 0 percent finer. This returns absent particle-size classes as zero rather
#' than `NA`, so complete schemes close to 100 percent for samples whose
#' retained percentages sum to 100. `NA` is reserved for thresholds that are
#' genuinely unresolved inside the finite observed size range. Fraction schemes
#' do not extrapolate unless `extrapolate = "warn_linear"` is passed explicitly.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scheme Built-in fraction scheme name.
#' @param normalize Normalization mode. `"none"` returns whole-sample
#'   percentages. `"fine_earth"` requires a scheme with a `gravel` component,
#'   excludes gravel rows, and normalizes the remaining non-gravel fractions
#'   against the non-gravel total.
#' @param interpolation_scale Interpolation scale passed to `gs_percent_finer()`.
#' @param unresolved Behavior when required thresholds cannot be calculated.
#'   `"warn_na"` warns and returns `NA` for affected components. `"error"`
#'   throws an error.
#' @param extrapolate Extrapolation behavior passed to `gs_percent_finer()`.
#'   The default `"error"` avoids silent extrapolation into open-ended terminal
#'   classes.
#'
#' @return A tibble with one row per sample and scheme component.
#' @export
gs_fractions <- function(x,
                         scheme = "wentworth_major",
                         normalize = c("none", "fine_earth"),
                         interpolation_scale = "phi",
                         unresolved = c("warn_na", "error"),
                         extrapolate = "error") {
  validate_gsd_tbl(x)
  scheme <- .validate_fraction_scheme(scheme)
  normalize <- match.arg(normalize)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  unresolved <- match.arg(unresolved)
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  .validate_fraction_normalize_scheme(scheme, normalize)
  components <- scheme_components(scheme)
  thresholds <- required_fraction_thresholds(components)
  lookup <- percent_finer_lookup(
    x,
    thresholds_mm = thresholds,
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate,
    unresolved = unresolved
  )

  sample_ids <- unique(as.character(x$sample_id))
  out <- lapply(
    sample_ids,
    fractions_one_sample,
    components = components,
    lookup = lookup,
    scheme = scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale
  )
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Calculate grain-size fraction percentages in wide form
#'
#' `gs_fractions_wide()` is a convenience wrapper around `gs_fractions()` that
#' returns one row per sample with one percentage column per fraction component.
#'
#' @inheritParams gs_fractions
#'
#' @return A tibble with one row per sample and component percentage columns.
#' @export
gs_fractions_wide <- function(x,
                              scheme = "wentworth_major",
                              normalize = c("none", "fine_earth"),
                              interpolation_scale = "phi",
                              unresolved = c("warn_na", "error"),
                              extrapolate = "error") {
  fractions <- gs_fractions(
    x,
    scheme = scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale,
    unresolved = unresolved,
    extrapolate = extrapolate
  )
  sample_ids <- unique(fractions$sample_id)
  components <- unique(fractions$component)
  out <- tibble::tibble(sample_id = sample_ids)

  for (component in components) {
    values <- fractions$percent[fractions$component == component]
    names(values) <- fractions$sample_id[fractions$component == component]
    out[[paste0(component, "_percent")]] <- unname(values[out$sample_id])
  }

  out
}
