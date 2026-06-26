resolve_column <- function(expr, env, data, arg_name) {
  if (is.character(expr) && length(expr) == 1) {
    col <- expr
  } else if (is.symbol(expr)) {
    col <- as.character(expr)

    if (!col %in% names(data) && exists(col, envir = env, inherits = TRUE)) {
      forwarded <- get(col, envir = env, inherits = TRUE)
      if (is.character(forwarded) && length(forwarded) == 1) {
        col <- forwarded
      }
    }
  } else {
    stop("`", arg_name, "` must be an unquoted column name or a string.", call. = FALSE)
  }

  if (!col %in% names(data)) {
    stop("`", arg_name, "` must refer to a column in `x`.", call. = FALSE)
  }

  col
}

normalize_size_unit <- function(size_unit) {
  size_unit <- match.arg(size_unit, c("mm", "um", "phi"))
  size_unit
}

sizes_to_um <- function(x, size_unit) {
  size <- suppressWarnings(as.numeric(as.character(x)))

  if (anyNA(size)) {
    stop("Size labels must be numeric or coercible to numeric values.", call. = FALSE)
  }

  if (any(size <= 0)) {
    stop("Size labels must be positive.", call. = FALSE)
  }

  switch(
    size_unit,
    mm = mm_to_um(size),
    um = size,
    phi = phi_to_um(size)
  )
}

values_to_percent <- function(value, sample_id, value_type) {
  value_type <- match.arg(value_type, c("proportion", "percent", "weight"))
  value <- suppressWarnings(as.numeric(value))

  if (anyNA(value)) {
    stop("Grain-size values must be numeric or coercible to numeric values.", call. = FALSE)
  }

  if (any(value < 0)) {
    stop("Grain-size values must be non-negative.", call. = FALSE)
  }

  if (value_type == "proportion") {
    return(value * 100)
  }

  if (value_type == "percent") {
    return(value)
  }

  totals <- stats::ave(value, sample_id, FUN = sum)
  if (any(totals <= 0)) {
    stop("Weights must sum to a positive value within each sample.", call. = FALSE)
  }

  value / totals * 100
}

build_sample_bins <- function(sample_data) {
  n <- nrow(sample_data)

  if (n < 2) {
    stop("Each sample must contain at least two size rows.", call. = FALSE)
  }

  raw_size_um <- sample_data$raw_size_um
  retained_percent <- sample_data$retained_percent

  lower <- raw_size_um
  upper <- c(NA_real_, raw_size_um[-n])
  lower[n] <- NA_real_
  upper[n] <- raw_size_um[n - 1]

  is_open_upper <- rep(FALSE, n)
  is_open_upper[1] <- TRUE

  is_open_lower <- rep(FALSE, n)
  is_open_lower[n] <- TRUE

  closed <- !is_open_lower & !is_open_upper
  midpoint_um <- rep(NA_real_, n)
  midpoint_um[closed] <- sqrt(lower[closed] * upper[closed])

  cum_coarser_percent <- cumsum(retained_percent)
  cum_finer_percent <- 100 - cum_coarser_percent

  tibble::tibble(
    sample_id = sample_data$sample_id,
    bin_id = seq_len(n),
    raw_size_um = raw_size_um,
    size_lower_um = lower,
    size_upper_um = upper,
    size_mid_um = midpoint_um,
    size_mid_phi = um_to_phi(midpoint_um),
    retained_percent = retained_percent,
    cum_finer_percent = cum_finer_percent,
    cum_coarser_percent = cum_coarser_percent,
    is_open_lower = is_open_lower,
    is_open_upper = is_open_upper,
    measurement_method = sample_data$measurement_method
  )
}

#' Read grain-size data from a delimited text file
#'
#' `read_gsd()` reads a comma-separated file and converts a long- or
#' wide-format table into a `gsd_tbl`.
#'
#' @param file Path to a CSV file.
#' @param sample_col Column containing sample identifiers. If omitted for
#'   long-format input, `read_gsd()` uses `"sample"` when that column exists.
#' @param size_col Column containing grain-size class labels or thresholds. If
#'   omitted for long-format input, `read_gsd()` uses `"size"` when that column
#'   exists.
#' @param value_col Column containing retained proportions, retained
#'   percentages, or weights. If omitted for long-format input, `read_gsd()`
#'   uses `"proportion"` when that column exists.
#' @param size_unit Unit for `size_col`. Supported values are `"mm"`, `"um"`,
#'   and `"phi"`.
#' @param value_type Scale for `value_col`. Supported values are
#'   `"proportion"`, `"percent"`, and `"weight"`.
#' @param measurement_method Measurement method to store in the output.
#' @param format Input table format. `"long"` reads one row per sample and
#'   grain-size class. `"wide"` reads grain-size classes from rows and sample
#'   identifiers from columns.
#'
#' @return A `gsd_tbl`.
#' @export
read_gsd <- function(file,
                     sample_col,
                     size_col,
                     value_col,
                     size_unit = "mm",
                     value_type = "proportion",
                     measurement_method = NA_character_,
                     format = c("long", "wide")) {
  format <- match.arg(format)

  if (format == "wide") {
    if (missing(size_col)) {
      size_col <- 1
    } else {
      size_col_expr <- substitute(size_col)
      size_col <- if (is.symbol(size_col_expr)) {
        as.character(size_col_expr)
      } else {
        eval(size_col_expr, parent.frame())
      }
    }
    return(read_gsd_wide(
      file = file,
      size_col = size_col,
      size_unit = size_unit,
      value_type = value_type,
      measurement_method = measurement_method
    ))
  }

  x <- readr::read_csv(file, show_col_types = FALSE)

  if (missing(sample_col) && "sample" %in% names(x)) {
    sample_col <- "sample"
  }
  if (missing(size_col) && "size" %in% names(x)) {
    size_col <- "size"
  }
  if (missing(value_col) && "proportion" %in% names(x)) {
    value_col <- "proportion"
  }

  if (missing(sample_col) || missing(size_col) || missing(value_col)) {
    stop(
      "`sample_col`, `size_col`, and `value_col` are required for long-format input.",
      call. = FALSE
    )
  }

  sample_col <- rlang::as_name(rlang::ensym(sample_col))
  size_col <- rlang::as_name(rlang::ensym(size_col))
  value_col <- rlang::as_name(rlang::ensym(value_col))

  as_gsd_tbl(
    x = x,
    sample_col = sample_col,
    size_col = size_col,
    value_col = value_col,
    size_unit = size_unit,
    value_type = value_type,
    measurement_method = measurement_method
  )
}

#' Convert long-format grain-size data to a `gsd_tbl`
#'
#' `as_gsd_tbl()` accepts one row per sample and grain-size class. Rows may be
#' ragged: different samples can have different size labels and different
#' numbers of classes. Within each sample, size labels are sorted internally
#' from coarse to fine before class boundaries are constructed.
#'
#' For sorted size labels `s1 > s2 > ... > sn`, bins are interpreted as
#' `> s1`, `s2` to `s1`, ..., and `< s(n - 1)`. The final row's numeric size
#' label is preserved in `raw_size_um`, but it is not used as the true lower
#' boundary of the terminal fine class.
#'
#' @param x A data frame containing long-format grain-size data.
#' @param sample_col Column containing sample identifiers.
#' @param size_col Column containing grain-size class labels or thresholds.
#' @param value_col Column containing retained proportions, retained
#'   percentages, or weights.
#' @param size_unit Unit for `size_col`. Supported values are `"mm"`, `"um"`,
#'   and `"phi"`.
#' @param value_type Scale for `value_col`. Supported values are
#'   `"proportion"`, `"percent"`, and `"weight"`.
#' @param measurement_method Measurement method to store in the output. A single
#'   string is recycled to all rows.
#'
#' @return A `gsd_tbl`.
#' @export
as_gsd_tbl <- function(x,
                       sample_col,
                       size_col,
                       value_col,
                       size_unit = "mm",
                       value_type = "proportion",
                       measurement_method = NA_character_) {
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame.", call. = FALSE)
  }

  size_unit <- normalize_size_unit(size_unit)
  value_type <- match.arg(value_type, c("proportion", "percent", "weight"))

  env <- parent.frame()
  sample_col <- resolve_column(substitute(sample_col), env, x, "sample_col")
  size_col <- resolve_column(substitute(size_col), env, x, "size_col")
  value_col <- resolve_column(substitute(value_col), env, x, "value_col")

  sample_id <- as.character(x[[sample_col]])
  if (anyNA(sample_id) || any(sample_id == "")) {
    stop("Sample identifiers must not be missing or empty.", call. = FALSE)
  }

  raw_size_um <- sizes_to_um(x[[size_col]], size_unit)
  retained_percent <- values_to_percent(x[[value_col]], sample_id, value_type)

  if (length(measurement_method) == 1) {
    measurement_method <- rep(measurement_method, length(sample_id))
  } else if (length(measurement_method) != length(sample_id)) {
    stop(
      "`measurement_method` must have length 1 or the same length as `x`.",
      call. = FALSE
    )
  }

  data <- tibble::tibble(
    sample_id = sample_id,
    raw_size_um = raw_size_um,
    retained_percent = retained_percent,
    measurement_method = as.character(measurement_method),
    input_order = seq_along(sample_id)
  )

  data <- data[order(data$sample_id, -data$raw_size_um, data$input_order), ]
  split_data <- split(data, data$sample_id, drop = TRUE)
  bins <- lapply(split_data, build_sample_bins)
  out <- do.call(rbind, unname(bins))
  rownames(out) <- NULL

  out <- new_gsd_tbl(out)
  validate_gsd_tbl(out)
  out
}
