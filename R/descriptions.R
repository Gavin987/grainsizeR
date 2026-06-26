#' Describe mean grain size from phi units
#'
#' @param phi A numeric vector of mean grain sizes in phi units.
#'
#' @return A character vector of grain-size class labels.
#' @export
describe_mean_size_phi <- function(phi) {
  out <- rep(NA_character_, length(phi))
  out[phi < -8] <- "boulder"
  out[phi >= -8 & phi < -6] <- "cobble"
  out[phi >= -6 & phi < -2] <- "pebble"
  out[phi >= -2 & phi < -1] <- "granule"
  out[phi >= -1 & phi < 0] <- "very coarse sand"
  out[phi >= 0 & phi < 1] <- "coarse sand"
  out[phi >= 1 & phi < 2] <- "medium sand"
  out[phi >= 2 & phi < 3] <- "fine sand"
  out[phi >= 3 & phi < 4] <- "very fine sand"
  out[phi >= 4 & phi < 5] <- "coarse silt"
  out[phi >= 5 & phi < 6] <- "medium silt"
  out[phi >= 6 & phi < 7] <- "fine silt"
  out[phi >= 7 & phi < 8] <- "very fine silt"
  out[phi >= 8] <- "clay"
  out
}

#' Describe Folk and Ward sorting
#'
#' @param sorting_phi A numeric vector of Folk and Ward sorting values in phi
#'   units.
#'
#' @return A character vector of sorting class labels.
#' @export
describe_sorting_fw <- function(sorting_phi) {
  out <- rep(NA_character_, length(sorting_phi))
  out[sorting_phi < 0.35] <- "very well sorted"
  out[sorting_phi >= 0.35 & sorting_phi < 0.50] <- "well sorted"
  out[sorting_phi >= 0.50 & sorting_phi < 0.71] <- "moderately well sorted"
  out[sorting_phi >= 0.71 & sorting_phi < 1.00] <- "moderately sorted"
  out[sorting_phi >= 1.00 & sorting_phi < 2.00] <- "poorly sorted"
  out[sorting_phi >= 2.00 & sorting_phi < 4.00] <- "very poorly sorted"
  out[sorting_phi >= 4.00] <- "extremely poorly sorted"
  out
}

#' Describe Folk and Ward skewness
#'
#' @param skewness A numeric vector of Folk and Ward skewness values.
#'
#' @return A character vector of skewness class labels.
#' @export
describe_skewness_fw <- function(skewness) {
  out <- rep(NA_character_, length(skewness))
  out[skewness >= 0.30] <- "strongly fine skewed"
  out[skewness >= 0.10 & skewness < 0.30] <- "fine skewed"
  out[skewness >= -0.10 & skewness < 0.10] <- "near symmetrical"
  out[skewness >= -0.30 & skewness < -0.10] <- "coarse skewed"
  out[skewness < -0.30] <- "strongly coarse skewed"
  out
}

#' Describe Folk and Ward kurtosis
#'
#' @param kurtosis A numeric vector of Folk and Ward kurtosis values.
#'
#' @return A character vector of kurtosis class labels.
#' @export
describe_kurtosis_fw <- function(kurtosis) {
  out <- rep(NA_character_, length(kurtosis))
  out[kurtosis < 0.67] <- "very platykurtic"
  out[kurtosis >= 0.67 & kurtosis < 0.90] <- "platykurtic"
  out[kurtosis >= 0.90 & kurtosis < 1.11] <- "mesokurtic"
  out[kurtosis >= 1.11 & kurtosis < 1.50] <- "leptokurtic"
  out[kurtosis >= 1.50 & kurtosis < 3.00] <- "very leptokurtic"
  out[kurtosis >= 3.00] <- "extremely leptokurtic"
  out
}

#' Describe grain-size terms
#'
#' `gs_size_terms()` assigns concise modified Udden-Wentworth-style size terms
#' to numeric grain sizes. The helper accepts phi, millimeter, or micrometer
#' input and uses the same class labels as `describe_mean_size_phi()`.
#'
#' The terms are useful for GRADISTAT-style printout layers, but they are not
#' full GRADISTAT sediment names or texture classifications.
#'
#' @param x Numeric grain sizes.
#' @param unit Unit of `x`. Supported values are `"phi"`, `"mm"`, and `"um"`.
#'
#' @return A character vector of size terms.
#' @export
gs_size_terms <- function(x, unit = c("phi", "mm", "um")) {
  unit <- match.arg(unit)
  if (!is.numeric(x)) {
    stop("`x` must be numeric.", call. = FALSE)
  }

  phi <- switch(
    unit,
    phi = x,
    mm = mm_to_phi(x),
    um = um_to_phi(x)
  )

  describe_mean_size_phi(phi)
}

descriptor_columns <- function(x, method) {
  if (method == "folk_ward") {
    return(c(
      mean = "mean_fw_phi",
      sorting = "sorting_fw_phi",
      skewness = "skewness_fw",
      kurtosis = "kurtosis_fw"
    ))
  }

  if (method == "logarithmic_moments") {
    return(c(
      mean = "mean_moment_phi",
      sorting = "sd_moment_phi",
      skewness = "skewness_moment",
      kurtosis = "kurtosis_moment"
    ))
  }

  if (all(c("mean_fw_phi", "sorting_fw_phi", "skewness_fw", "kurtosis_fw") %in% names(x))) {
    return(descriptor_columns(x, "folk_ward"))
  }

  if (all(c("mean_moment_phi", "sd_moment_phi", "skewness_moment", "kurtosis_moment") %in% names(x))) {
    return(descriptor_columns(x, "logarithmic_moments"))
  }

  NULL
}

#' Attach GRADISTAT-style parameter descriptions
#'
#' `gs_describe_parameters()` appends descriptive terms for mean grain size,
#' sorting, skewness, and kurtosis to tables returned by `gs_folk_ward()`,
#' `gs_folkward()`, `gs_moments()`, or `gs_parameters()`, or to any data frame
#' with recognized statistic columns.
#'
#' Supported methods are Folk and Ward graphical statistics and logarithmic
#' moment statistics in phi units. The output is deterministic and conservative:
#' rows with missing required values are marked rather than silently described.
#' These descriptions support a GRADISTAT-style printout layer, but they do not
#' implement full GRADISTAT sediment naming or texture classification.
#'
#' @param x A data frame containing recognized grain-size statistic columns.
#' @param method Descriptor method. `"auto"` detects recognized columns,
#'   `"folk_ward"` uses Folk and Ward columns, and `"logarithmic_moments"` uses
#'   moment columns in phi units.
#'
#' @return The input data frame with descriptor columns appended.
#' @export
gs_describe_parameters <- function(x, method = c("auto", "folk_ward", "logarithmic_moments")) {
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame.", call. = FALSE)
  }

  method <- match.arg(method)
  out <- tibble::as_tibble(x)
  selected_method <- method
  cols <- if (method == "auto") {
    descriptor_columns(out, "auto")
  } else {
    descriptor_columns(out, method)
  }

  if (is.null(cols)) {
    out$mean_description <- NA_character_
    out$sorting_description <- NA_character_
    out$skewness_description <- NA_character_
    out$kurtosis_description <- NA_character_
    out$description_method <- if (method == "auto") NA_character_ else method
    out$description_status <- if (method == "auto") {
      "missing_required_values"
    } else {
      "unsupported_method"
    }
    return(out)
  }

  if (method == "auto") {
    selected_method <- if (identical(cols[["mean"]], "mean_fw_phi")) {
      "folk_ward"
    } else {
      "logarithmic_moments"
    }
  }

  required <- unname(cols)
  missing_required <- !required %in% names(out)
  if (any(missing_required)) {
    other_method_complete <- if (method == "folk_ward") {
      all(unname(descriptor_columns(out, "logarithmic_moments")) %in% names(out))
    } else if (method == "logarithmic_moments") {
      all(unname(descriptor_columns(out, "folk_ward")) %in% names(out))
    } else {
      FALSE
    }
    out$mean_description <- NA_character_
    out$sorting_description <- NA_character_
    out$skewness_description <- NA_character_
    out$kurtosis_description <- NA_character_
    out$description_method <- selected_method
    out$description_status <- if (other_method_complete) "unsupported_method" else "missing_required_values"
    return(out)
  }

  values_present <- stats::complete.cases(out[required])
  out$mean_description <- NA_character_
  out$sorting_description <- NA_character_
  out$skewness_description <- NA_character_
  out$kurtosis_description <- NA_character_
  out$description_method <- selected_method
  out$description_status <- ifelse(values_present, "described", "missing_required_values")

  out$mean_description[values_present] <- describe_mean_size_phi(out[[cols[["mean"]]]][values_present])
  out$sorting_description[values_present] <- describe_sorting_fw(out[[cols[["sorting"]]]][values_present])
  out$skewness_description[values_present] <- describe_skewness_fw(out[[cols[["skewness"]]]][values_present])
  out$kurtosis_description[values_present] <- describe_kurtosis_fw(out[[cols[["kurtosis"]]]][values_present])

  unresolved <- values_present & (
    is.na(out$mean_description) |
      is.na(out$sorting_description) |
      is.na(out$skewness_description) |
      is.na(out$kurtosis_description)
  )
  out$description_status[unresolved] <- "out_of_range"
  out
}
