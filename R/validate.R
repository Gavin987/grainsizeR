#' Validate a grain-size distribution tibble
#'
#' `validate_gsd_tbl()` checks that an object has the required `gsd_tbl`
#' columns, that open-ended class flags and boundaries are internally
#' consistent, and optionally that retained percentages sum to approximately
#' 100 within each sample.
#'
#' @param x A `gsd_tbl` object.
#' @param check_sum Should retained percentages be checked within each sample?
#' @param tolerance Numeric tolerance used when checking sample totals.
#'
#' @return Invisibly returns `x` if validation succeeds.
#' @export
validate_gsd_tbl <- function(x, check_sum = TRUE, tolerance = 1e-6) {
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

  numeric_cols <- c(
    "raw_size_um",
    "size_lower_um",
    "size_upper_um",
    "size_mid_um",
    "size_mid_phi",
    "retained_percent",
    "cum_finer_percent",
    "cum_coarser_percent"
  )

  bad_numeric <- numeric_cols[!vapply(x[numeric_cols], is.numeric, logical(1))]
  if (length(bad_numeric) > 0) {
    stop(
      "These columns must be numeric: ",
      paste(bad_numeric, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.logical(x$is_open_lower) || !is.logical(x$is_open_upper)) {
    stop("Open-ended class flags must be logical.", call. = FALSE)
  }

  if (any(x$retained_percent < 0 | x$retained_percent > 100, na.rm = TRUE)) {
    stop("`retained_percent` values must be between 0 and 100.", call. = FALSE)
  }

  if (any(x$is_open_lower & !is.na(x$size_lower_um))) {
    stop("Lower-open classes must have `NA` lower boundaries.", call. = FALSE)
  }

  if (any(x$is_open_upper & !is.na(x$size_upper_um))) {
    stop("Upper-open classes must have `NA` upper boundaries.", call. = FALSE)
  }

  closed <- !x$is_open_lower & !x$is_open_upper
  if (any(is.na(x$size_mid_um[closed]) | is.na(x$size_mid_phi[closed]))) {
    stop("Closed classes must have midpoint values.", call. = FALSE)
  }

  if (any(!is.na(x$size_mid_um[!closed]) | !is.na(x$size_mid_phi[!closed]))) {
    stop("Open-ended classes must have `NA` midpoint values.", call. = FALSE)
  }

  if (check_sum) {
    totals <- rowsum(x$retained_percent, x$sample_id, reorder = FALSE)
    bad_samples <- rownames(totals)[abs(drop(totals) - 100) > tolerance]

    if (length(bad_samples) > 0) {
      stop(
        "`retained_percent` must sum to 100 within each sample. Failed samples: ",
        paste(bad_samples, collapse = ", "),
        call. = FALSE
      )
    }
  }

  invisible(x)
}
