diagnostic_status_levels <- c("error", "warning", "info", "ok", "not_applicable")

diagnostic_severity_rank <- c(none = 0L, low = 1L, medium = 2L, high = 3L)

diagnostic_row <- function(sample_id,
                           check,
                           status,
                           severity,
                           value = NA_character_,
                           expected = NA_character_,
                           parameter = NA_character_,
                           message,
                           recommendation = NA_character_) {
  tibble::tibble(
    sample_id = as.character(sample_id),
    check = check,
    status = status,
    severity = severity,
    value = as.character(value),
    expected = as.character(expected),
    parameter = as.character(parameter),
    message = message,
    recommendation = recommendation
  )
}

diagnostic_bind <- function(rows) {
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0) {
    return(tibble::tibble(
      sample_id = character(),
      check = character(),
      status = character(),
      severity = character(),
      value = character(),
      expected = character(),
      parameter = character(),
      message = character(),
      recommendation = character()
    ))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

diagnostic_check_input <- function(x) {
  if (!is_gsd_tbl(x)) {
    stop("`x` must be a gsd_tbl.", call. = FALSE)
  }

  missing_cols <- setdiff(gsd_tbl_columns, names(x))
  if (length(missing_cols) > 0) {
    stop(
      "`x` is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(x)
}

diagnostic_sample_rows <- function(sample_data, retained_tolerance, fine_boundary_um) {
  sample_id <- sample_data$sample_id[1]
  retained <- sample_data$retained_percent
  total <- sum(retained, na.rm = TRUE)
  finite_retained <- retained[is.finite(retained)]
  finite_boundaries <- sample_data$raw_size_um[
    is.finite(sample_data$raw_size_um) &
      !sample_data$is_open_lower &
      !sample_data$is_open_upper
  ]
  all_finite_boundaries <- sample_data$raw_size_um[
    is.finite(sample_data$raw_size_um) &
      !sample_data$is_open_lower
  ]
  has_open_fine <- any(sample_data$is_open_lower & retained > 0, na.rm = TRUE)
  has_open_coarse <- any(sample_data$is_open_upper & retained > 0, na.rm = TRUE)
  has_fine_resolution <- any(all_finite_boundaries < fine_boundary_um, na.rm = TRUE)

  rows <- list()
  row_id <- 1L

  rows[[row_id]] <- if (anyNA(retained) || any(!is.finite(retained))) {
    diagnostic_row(
      sample_id,
      "missing_values",
      "error",
      "high",
      value = sum(!is.finite(retained) | is.na(retained)),
      expected = "finite retained percentages",
      message = "Retained percentages contain missing or non-finite values.",
      recommendation = "Review the input table before calculating grain-size parameters."
    )
  } else {
    diagnostic_row(
      sample_id,
      "missing_values",
      "ok",
      "none",
      value = 0,
      expected = "finite retained percentages",
      message = "Retained percentages are finite.",
      recommendation = NA_character_
    )
  }
  row_id <- row_id + 1L

  rows[[row_id]] <- if (any(retained < 0, na.rm = TRUE)) {
    diagnostic_row(
      sample_id,
      "negative_values",
      "error",
      "high",
      value = sum(retained < 0, na.rm = TRUE),
      expected = "no negative retained percentages",
      message = "One or more retained percentages are negative.",
      recommendation = "Correct negative retained values before analysis."
    )
  } else {
    diagnostic_row(
      sample_id,
      "negative_values",
      "ok",
      "none",
      value = 0,
      expected = "no negative retained percentages",
      message = "No negative retained percentages were found.",
      recommendation = NA_character_
    )
  }
  row_id <- row_id + 1L

  rows[[row_id]] <- if (!is.finite(total) || total <= 0) {
    diagnostic_row(
      sample_id,
      "zero_total",
      "error",
      "high",
      value = total,
      expected = "> 0",
      message = "The retained total is zero or non-finite.",
      recommendation = "Provide positive retained values before analysis."
    )
  } else {
    diagnostic_row(
      sample_id,
      "zero_total",
      "ok",
      "none",
      value = total,
      expected = "> 0",
      message = "The retained total is positive.",
      recommendation = NA_character_
    )
  }
  row_id <- row_id + 1L

  total_status <- if (!is.finite(total) || total <= 0) {
    c("error", "high")
  } else if (abs(total - 100) > retained_tolerance) {
    c("warning", "medium")
  } else {
    c("ok", "none")
  }
  rows[[row_id]] <- diagnostic_row(
    sample_id,
    "retained_total",
    total_status[1],
    total_status[2],
    value = total,
    expected = paste0("100 +/- ", retained_tolerance),
    message = if (total_status[1] == "ok") {
      "Retained percentages sum to approximately 100."
    } else {
      "Retained percentages do not sum to approximately 100."
    },
    recommendation = if (total_status[1] == "ok") {
      NA_character_
    } else {
      "Check input values and normalization before interpreting summaries."
    }
  )
  row_id <- row_id + 1L

  duplicate_count <- sum(duplicated(sample_data$raw_size_um))
  rows[[row_id]] <- diagnostic_row(
    sample_id,
    "duplicate_size_classes",
    if (duplicate_count > 0) "warning" else "ok",
    if (duplicate_count > 0) "medium" else "none",
    value = duplicate_count,
    expected = "0 duplicate size labels",
    message = if (duplicate_count > 0) {
      "Duplicate grain-size class labels were found."
    } else {
      "No duplicate grain-size class labels were found."
    },
    recommendation = if (duplicate_count > 0) {
      "Combine or review duplicate classes before analysis."
    } else {
      NA_character_
    }
  )
  row_id <- row_id + 1L

  ordered <- all(diff(sample_data$raw_size_um) <= 0)
  rows[[row_id]] <- diagnostic_row(
    sample_id,
    "size_order",
    if (ordered) "ok" else "warning",
    if (ordered) "none" else "low",
    value = if (ordered) "decreasing" else "not decreasing",
    expected = "coarse-to-fine order",
    message = if (ordered) {
      "Size classes are ordered from coarse to fine."
    } else {
      "Size classes are not ordered from coarse to fine."
    },
    recommendation = if (ordered) {
      NA_character_
    } else {
      "Review size ordering if the object was manually modified."
    }
  )
  row_id <- row_id + 1L

  rows[[row_id]] <- diagnostic_row(
    sample_id,
    "open_fine_tail",
    if (has_open_fine) "info" else "ok",
    if (has_open_fine) "low" else "none",
    value = has_open_fine,
    expected = "reported explicitly",
    message = if (has_open_fine) {
      "The sample has retained material in an open-ended fine class."
    } else {
      "No retained material was found in an open-ended fine class."
    },
    recommendation = if (has_open_fine) {
      "Fine-end D-values and clay/silt thresholds may require finer measurements or explicit extrapolation."
    } else {
      NA_character_
    }
  )
  row_id <- row_id + 1L

  rows[[row_id]] <- diagnostic_row(
    sample_id,
    "open_coarse_tail",
    if (has_open_coarse) "info" else "ok",
    if (has_open_coarse) "low" else "none",
    value = has_open_coarse,
    expected = "reported explicitly",
    message = if (has_open_coarse) {
      "The sample has retained material in an open-ended coarse class."
    } else {
      "No retained material was found in an open-ended coarse class."
    },
    recommendation = if (has_open_coarse) {
      "Coarse-end D-values may require coarser measurements or explicit extrapolation."
    } else {
      NA_character_
    }
  )
  row_id <- row_id + 1L

  rows[[row_id]] <- diagnostic_row(
    sample_id,
    "fine_resolution",
    if (has_fine_resolution) "ok" else "info",
    if (has_fine_resolution) "none" else "low",
    value = length(all_finite_boundaries[all_finite_boundaries < fine_boundary_um]),
    expected = paste0("finite boundaries below ", fine_boundary_um, " um"),
    message = if (has_fine_resolution) {
      "Finite fine-resolution boundaries are present below the selected fine boundary."
    } else {
      "No finite fine-resolution boundaries were found below the selected fine boundary."
    },
    recommendation = if (has_fine_resolution) {
      NA_character_
    } else {
      "Data without finite fine-resolution boundaries may be suitable for coarse summaries but may not resolve clay/silt thresholds."
    }
  )

  diagnostic_bind(rows)
}

diagnostic_d_value_rows <- function(sample_data, d_values, interpolation_scale, extrapolate) {
  sample_id <- sample_data$sample_id[1]

  # One batched call for every requested D-value instead of one call each.
  # `extrapolate = "warn_linear"` never throws, so the per-value resolvable
  # vs. extrapolated vs. unresolved decision below is reconstructed from the
  # `extrapolated` flag rather than from a caught error; the interpolated
  # values themselves are identical to calling with `extrapolate = "error"`
  # for every value that would not have thrown.
  result <- tryCatch(
    suppressWarnings(gs_d_values(
      sample_data,
      probs = d_values,
      interpolation_scale = interpolation_scale,
      extrapolate = "warn_linear"
    )),
    error = function(err) err
  )

  rows <- vector("list", length(d_values))
  for (i in seq_along(d_values)) {
    prob <- d_values[i]
    if (inherits(result, "error") || (extrapolate == "error" && isTRUE(result$extrapolated[i]))) {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "d_value_resolvable",
        "warning",
        "medium",
        value = "unresolved",
        expected = "finite-boundary interpolation",
        parameter = paste0("D", prob),
        message = "The requested D-value is unresolved under the selected open-tail policy.",
        recommendation = "Provide finer or coarser measurements, or explicitly use extrapolation when it is appropriate and documented."
      )
    } else if (isTRUE(result$extrapolated[i])) {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "d_value_resolvable",
        "warning",
        "low",
        value = result$grain_size_um[i],
        expected = "finite-boundary interpolation",
        parameter = paste0("D", prob),
        message = "The requested D-value required explicit extrapolation.",
        recommendation = "Document the extrapolation policy when reporting this D-value."
      )
    } else {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "d_value_resolvable",
        "ok",
        "none",
        value = result$grain_size_um[i],
        expected = "finite-boundary interpolation",
        parameter = paste0("D", prob),
        message = "The requested D-value is resolvable from finite boundaries.",
        recommendation = NA_character_
      )
    }
  }

  diagnostic_bind(rows)
}

diagnostic_threshold_rows <- function(sample_data, thresholds_um, interpolation_scale, extrapolate) {
  sample_id <- sample_data$sample_id[1]

  # One batched call for every requested threshold instead of one call each;
  # see `diagnostic_d_value_rows()` for why `extrapolate = "warn_linear"` here
  # preserves the per-value resolvable/extrapolated/unresolved outcome.
  result <- tryCatch(
    suppressWarnings(gs_percent_finer(
      sample_data,
      sizes = thresholds_um,
      size_unit = "um",
      interpolation_scale = interpolation_scale,
      extrapolate = "warn_linear"
    )),
    error = function(err) err
  )

  rows <- vector("list", length(thresholds_um))
  for (i in seq_along(thresholds_um)) {
    threshold <- thresholds_um[i]
    parameter <- paste0(threshold, " um")
    if (inherits(result, "error") || (extrapolate == "error" && isTRUE(result$extrapolated[i]))) {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "threshold_resolvable",
        "warning",
        "medium",
        value = "unresolved",
        expected = "threshold bracketed by finite boundaries",
        parameter = parameter,
        message = "The requested threshold is not resolvable under the selected open-tail policy.",
        recommendation = "Use finer/coarser measurements for this threshold or explicitly document extrapolation."
      )
    } else if (isTRUE(result$extrapolated[i])) {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "threshold_resolvable",
        "warning",
        "low",
        value = result$percent_finer[i],
        expected = "threshold bracketed by finite boundaries",
        parameter = parameter,
        message = "The requested threshold required explicit extrapolation.",
        recommendation = "Document the extrapolation policy when reporting this threshold."
      )
    } else {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "threshold_resolvable",
        "ok",
        "none",
        value = result$percent_finer[i],
        expected = "threshold bracketed by finite boundaries",
        parameter = parameter,
        message = "The requested threshold is resolvable from finite boundaries.",
        recommendation = NA_character_
      )
    }
  }

  diagnostic_bind(rows)
}

diagnostic_fraction_rows <- function(sample_data, fraction_schemes, interpolation_scale, extrapolate) {
  sample_id <- sample_data$sample_id[1]
  rows <- vector("list", length(fraction_schemes))

  for (i in seq_along(fraction_schemes)) {
    scheme <- fraction_schemes[i]
    result <- tryCatch(
      suppressWarnings(gs_fractions(
        sample_data,
        scheme = scheme,
        interpolation_scale = interpolation_scale,
        unresolved = "warn_na",
        extrapolate = extrapolate
      )),
      error = function(err) err
    )

    if (inherits(result, "error")) {
      rows[[i]] <- diagnostic_row(
        sample_id,
        "fraction_scheme_resolvable",
        "warning",
        "medium",
        value = "unresolved",
        expected = "all required scheme thresholds resolvable",
        parameter = scheme,
        message = "The fraction scheme could not be evaluated for this sample.",
        recommendation = "Review scheme thresholds and provide measurements that bracket required boundaries."
      )
    } else {
      all_resolved <- all(result$resolved)
      rows[[i]] <- diagnostic_row(
        sample_id,
        "fraction_scheme_resolvable",
        if (all_resolved) "ok" else "warning",
        if (all_resolved) "none" else "medium",
        value = if (all_resolved) "resolved" else "partly unresolved",
        expected = "all required scheme thresholds resolvable",
        parameter = scheme,
        message = if (all_resolved) {
          "All required thresholds for this fraction scheme are resolvable."
        } else {
          "One or more required thresholds for this fraction scheme are unresolved."
        },
        recommendation = if (all_resolved) {
          NA_character_
        } else if (scheme == "wentworth_major") {
          "Review measured boundaries or document unresolved coarse fraction behavior."
        } else {
          "Hydrometer, pipette, laser, or other fine-resolution measurements may be needed for clay/silt/sand texture schemes."
        }
      )
    }
  }

  diagnostic_bind(rows)
}

diagnostic_hydrometer_row <- function(sample_data,
                                      fine_boundary_um,
                                      hydrometer_trigger_percent,
                                      interpolation_scale,
                                      extrapolate) {
  sample_id <- sample_data$sample_id[1]
  fine_resolution <- any(
    is.finite(sample_data$raw_size_um) &
      !sample_data$is_open_lower &
      sample_data$raw_size_um < fine_boundary_um,
    na.rm = TRUE
  )

  result <- tryCatch(
    suppressWarnings(gs_percent_finer(
      sample_data,
      sizes = fine_boundary_um,
      size_unit = "um",
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )),
    error = function(err) err
  )

  if (inherits(result, "error")) {
    return(diagnostic_row(
      sample_id,
      "hydrometer_expected",
      "warning",
      "medium",
      value = "unresolved",
      expected = paste0("percent finer at ", fine_boundary_um, " um"),
      parameter = paste0(fine_boundary_um, " um"),
      message = "The workflow diagnostic could not resolve percent finer at the selected fine boundary.",
      recommendation = "Review fine-end data before deciding whether hydrometer, pipette, laser, or other fine-resolution measurements are expected."
    ))
  }

  fine_percent <- result$percent_finer[1]
  if (fine_percent > hydrometer_trigger_percent && !fine_resolution) {
    status <- "warning"
    severity <- "medium"
    message <- "Material finer than the selected boundary exceeds the workflow trigger, but no finite fine-resolution boundaries are present."
    recommendation <- "Hydrometer, pipette, laser, or equivalent fine-resolution measurements may be expected for this workflow."
  } else if (fine_percent <= hydrometer_trigger_percent && !fine_resolution) {
    status <- "info"
    severity <- "low"
    message <- "Material finer than the selected boundary does not exceed the workflow trigger, and fine-resolution boundaries are absent."
    recommendation <- "Document that fine-resolution measurements were not expected under this workflow rule."
  } else {
    status <- "ok"
    severity <- "none"
    message <- "Fine-resolution boundaries are present or the workflow trigger is not a concern."
    recommendation <- NA_character_
  }

  diagnostic_row(
    sample_id,
    "hydrometer_expected",
    status,
    severity,
    value = fine_percent,
    expected = paste0("hydrometer trigger > ", hydrometer_trigger_percent, "% finer than ", fine_boundary_um, " um"),
    parameter = paste0(fine_boundary_um, " um"),
    message = message,
    recommendation = recommendation
  )
}

diagnostic_summary_output <- function(long) {
  sample_ids <- unique(long$sample_id)
  split_data <- split(long, long$sample_id, drop = TRUE)
  rows <- lapply(sample_ids, function(sample_id) {
    x <- split_data[[sample_id]]
    n_error <- sum(x$status == "error")
    n_warning <- sum(x$status == "warning")
    n_info <- sum(x$status == "info")
    n_ok <- sum(x$status == "ok")
    overall_status <- if (n_error > 0) {
      "error"
    } else if (n_warning > 0) {
      "warning"
    } else if (n_info > 0) {
      "info"
    } else {
      "ok"
    }
    tibble::tibble(
      sample_id = sample_id,
      n_ok = n_ok,
      n_warning = n_warning,
      n_error = n_error,
      n_info = n_info,
      has_error = n_error > 0,
      has_warning = n_warning > 0,
      overall_status = overall_status
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

diagnostic_wide_output <- function(long) {
  summary <- diagnostic_summary_output(long)
  checks <- sort(unique(long$check))

  # Group once by (sample_id, check) instead of re-scanning the full `long`
  # table for every sample/check combination.
  status_order <- match(long$status, diagnostic_status_levels)
  group_key <- paste(long$sample_id, long$check, sep = "\r")
  groups <- split(seq_len(nrow(long)), group_key)
  worst_status <- vapply(groups, function(idx) {
    long$status[idx[which.min(status_order[idx])]]
  }, character(1))

  for (check in checks) {
    lookup_key <- paste(summary$sample_id, check, sep = "\r")
    values <- unname(worst_status[lookup_key])
    values[is.na(values)] <- "not_applicable"
    summary[[paste0(check, "_status")]] <- values
  }

  summary
}

#' Diagnose grain-size data quality and resolvability
#'
#' `gs_diagnostics()` reports data-quality and computational-resolvability
#' checks for a `gsd_tbl`. It is designed to be run before D-values,
#' percent-finer thresholds, fraction schemes, summary tables, or texture
#' workflows.
#'
#' Diagnostics are not a replacement for domain judgment. The hydrometer
#' trigger check is a workflow diagnostic, not a universal scientific rule.
#' Open-ended terminal bins are reported explicitly and are not silently treated
#' as bounded intervals.
#'
#' @param x A valid `gsd_tbl` object.
#' @param d_values Numeric D-value percentiles to check.
#' @param thresholds_um Numeric grain-size thresholds, in micrometers, to check
#'   with the package percent-finer convention.
#' @param fraction_schemes Built-in fraction schemes to check for threshold
#'   resolvability.
#' @param retained_tolerance Tolerance for retained percentages summing to 100.
#' @param fine_boundary_um Boundary used for fine-resolution and hydrometer
#'   workflow diagnostics.
#' @param hydrometer_trigger_percent Workflow trigger for the percent finer
#'   than `fine_boundary_um`.
#' @param extrapolate Extrapolation behavior passed to lower-level
#'   resolvability checks. The default `"error"` reports open-tail limitations
#'   instead of extrapolating.
#' @param output Output shape. `"long"` returns one row per sample and check.
#'   `"summary"` returns counts by sample. `"wide"` returns compact status
#'   columns by sample.
#'
#' @return A tibble of diagnostics.
#' @export
gs_diagnostics <- function(
    x,
    d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
    thresholds_um = c(2, 20, 50, 60, 62.5, 63, 2000),
    fraction_schemes = c("wentworth_major", "gradistat", "usda", "isss", "uk_ssew"),
    retained_tolerance = 1e-6,
    fine_boundary_um = 63,
    hydrometer_trigger_percent = 10,
    extrapolate = c("error", "warn_linear"),
    output = c("long", "wide", "summary")) {
  diagnostic_check_input(x)
  extrapolate <- match.arg(extrapolate)
  output <- match.arg(output)

  if (!is.numeric(d_values) || anyNA(d_values) || any(d_values < 0 | d_values > 100)) {
    stop("`d_values` must be numeric percentiles on the 0-100 scale.", call. = FALSE)
  }
  if (!is.numeric(thresholds_um) || anyNA(thresholds_um) || any(thresholds_um <= 0)) {
    stop("`thresholds_um` must contain positive numeric thresholds.", call. = FALSE)
  }
  if (!is.numeric(retained_tolerance) || length(retained_tolerance) != 1 || retained_tolerance < 0) {
    stop("`retained_tolerance` must be a non-negative number.", call. = FALSE)
  }

  available_schemes <- unique(gs_fraction_schemes()$scheme)
  unknown_schemes <- setdiff(fraction_schemes, available_schemes)
  if (length(unknown_schemes) > 0) {
    stop("Unknown fraction schemes: ", paste(unknown_schemes, collapse = ", "), call. = FALSE)
  }

  split_data <- split(x, x$sample_id, drop = TRUE)
  rows <- lapply(split_data, function(sample_data) {
    diagnostic_bind(list(
      diagnostic_sample_rows(sample_data, retained_tolerance, fine_boundary_um),
      diagnostic_hydrometer_row(
        sample_data,
        fine_boundary_um = fine_boundary_um,
        hydrometer_trigger_percent = hydrometer_trigger_percent,
        interpolation_scale = "phi",
        extrapolate = extrapolate
      ),
      diagnostic_d_value_rows(
        sample_data,
        d_values = d_values,
        interpolation_scale = "phi",
        extrapolate = extrapolate
      ),
      diagnostic_threshold_rows(
        sample_data,
        thresholds_um = thresholds_um,
        interpolation_scale = "phi",
        extrapolate = extrapolate
      ),
      diagnostic_fraction_rows(
        sample_data,
        fraction_schemes = fraction_schemes,
        interpolation_scale = "phi",
        extrapolate = extrapolate
      )
    ))
  })

  long <- diagnostic_bind(rows)
  long$status <- factor(long$status, levels = c("ok", "warning", "error", "info", "not_applicable"))
  long$status <- as.character(long$status)
  long$severity <- factor(long$severity, levels = names(diagnostic_severity_rank))
  long$severity <- as.character(long$severity)

  if (output == "summary") {
    return(diagnostic_summary_output(long))
  }
  if (output == "wide") {
    return(diagnostic_wide_output(long))
  }
  long
}
