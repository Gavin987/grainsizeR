scheme_components <- function(scheme) {
  schemes <- gs_fraction_schemes()
  out <- schemes[schemes$scheme == scheme, ]
  if (nrow(out) == 0) {
    stop("Unknown fraction scheme: ", scheme, call. = FALSE)
  }
  out
}

required_fraction_thresholds <- function(components) {
  sort(unique(c(
    components$lower_um[is.finite(components$lower_um) & components$lower_um > 0],
    components$upper_um[is.finite(components$upper_um) & components$upper_um > 0]
  )))
}

percent_finer_lookup <- function(x, thresholds, interpolation_scale, extrapolate, unresolved) {
  sample_ids <- unique(as.character(x$sample_id))

  if (length(thresholds) == 0) {
    return(tibble::tibble(
      sample_id = character(),
      threshold_um = numeric(),
      percent_finer = numeric(),
      resolved = logical()
    ))
  }

  result <- tryCatch(
    gs_percent_finer(
      x,
      sizes = thresholds,
      size_unit = "um",
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    ),
    error = function(err) {
      if (unresolved == "error") {
        stop(
          "Required fraction thresholds could not be resolved: ",
          conditionMessage(err),
          call. = FALSE
        )
      }
      warning(
        "Some required fraction thresholds could not be resolved; affected components are returned as NA.",
        call. = FALSE
      )
      NULL
    }
  )

  if (!is.null(result)) {
    return(tibble::tibble(
      sample_id = result$sample_id,
      threshold_um = result$threshold_um,
      percent_finer = result$percent_finer,
      resolved = TRUE
    ))
  }

  rows <- list()
  row_id <- 1
  for (sample_id in sample_ids) {
    sample_x <- x[x$sample_id == sample_id, ]
    for (threshold in thresholds) {
      one <- tryCatch(
        gs_percent_finer(
          sample_x,
          sizes = threshold,
          size_unit = "um",
          interpolation_scale = interpolation_scale,
          extrapolate = extrapolate
        ),
        error = function(err) NULL
      )

      if (is.null(one)) {
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_um = threshold,
          percent_finer = NA_real_,
          resolved = FALSE
        )
      } else {
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_um = threshold,
          percent_finer = one$percent_finer,
          resolved = TRUE
        )
      }
      row_id <- row_id + 1
    }
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

lookup_threshold <- function(lookup, sample_id, threshold) {
  row <- lookup[lookup$sample_id == sample_id & lookup$threshold_um == threshold, ]
  if (nrow(row) == 0) {
    return(list(value = NA_real_, resolved = FALSE))
  }
  list(value = row$percent_finer[1], resolved = row$resolved[1])
}

component_percent <- function(component, lookup, sample_id) {
  lower <- component$lower_um
  upper <- component$upper_um

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
#' named built-in particle-size scheme. Fractions are calculated from
#' cumulative percent-finer values at scheme thresholds by calling
#' `gs_percent_finer()` for all finite scheme boundaries.
#'
#' Scheme thresholds do not need to match observed grain-size boundaries. When
#' thresholds such as 2, 20, 50, 60, or 63 um are bracketed by finite class
#' boundaries, percent-finer values are interpolated on the cumulative curve.
#' Complete sand, silt, and clay fractions require the relevant scheme
#' boundaries to be resolvable. If a required threshold falls inside an
#' open-ended terminal class, `unresolved` controls whether affected components
#' are returned as `NA` or the calculation errors. Fraction schemes do not
#' extrapolate unless `extrapolate = "warn_linear"` is passed explicitly.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scheme Built-in fraction scheme name.
#' @param normalize Normalization mode. `"none"` returns whole-sample
#'   percentages. `"fine_earth"` excludes gravel rows and normalizes the
#'   remaining non-gravel fractions against the non-gravel total.
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
                         scheme = c(
                           "wentworth_major",
                           "gradistat",
                           "usda_tt",
                           "isss",
                           "uk_ssew",
                           "hypres",
                           "germany_63",
                           "australia_20",
                           "sweden_60"
                         ),
                         normalize = c("none", "fine_earth"),
                         interpolation_scale = "phi",
                         unresolved = c("warn_na", "error"),
                         extrapolate = "error") {
  validate_gsd_tbl(x)
  scheme <- match.arg(scheme)
  normalize <- match.arg(normalize)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  unresolved <- match.arg(unresolved)
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  components <- scheme_components(scheme)
  thresholds <- required_fraction_thresholds(components)
  lookup <- percent_finer_lookup(
    x,
    thresholds = thresholds,
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
                              scheme = c(
                                "wentworth_major",
                                "gradistat",
                                "usda_tt",
                                "isss",
                                "uk_ssew",
                                "hypres",
                                "germany_63",
                                "australia_20",
                                "sweden_60"
                              ),
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
