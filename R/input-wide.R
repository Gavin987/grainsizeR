parse_wide_size_labels <- function(labels, size_unit) {
  labels <- trimws(as.character(labels))
  terminal_fine <- grepl("^<\\s*", labels)
  numeric_labels <- sub("^<\\s*", "", labels)

  raw_size_um <- sizes_to_um(numeric_labels, size_unit)

  list(
    raw_size_um = raw_size_um,
    terminal_fine = terminal_fine
  )
}

resolve_wide_size_col <- function(size_col, data) {
  if (is.numeric(size_col) && length(size_col) == 1) {
    if (is.na(size_col) || size_col < 1 || size_col > ncol(data)) {
      stop("`size_col` must identify a column in the wide table.", call. = FALSE)
    }
    return(names(data)[[size_col]])
  }

  if (is.character(size_col) && length(size_col) == 1) {
    if (!size_col %in% names(data)) {
      stop("`size_col` must identify a column in the wide table.", call. = FALSE)
    }
    return(size_col)
  }

  stop("`size_col` must be a column index or a column name.", call. = FALSE)
}

#' Read wide-format grain-size data from a CSV file
#'
#' `read_gsd_wide()` reads a table where grain-size classes are stored in rows
#' and sample identifiers are stored in columns. Values are retained
#' proportions, retained percentages, or weights.
#'
#' Numeric size labels such as `"2"` and `"0.0625"` are interpreted as class
#' thresholds. Terminal fine labels such as `"<0.0625"` in a strict
#' Wentworth-style example are parsed as the numeric threshold while still
#' producing an open-ended fine class in the returned `gsd_tbl`. A size label
#' of `"0"` is treated as a pan or lower open-ended row and imported with the
#' package's 1 um lower-tail marker.
#'
#' @param file Path to a CSV file.
#' @param size_col Column containing grain-size class labels or thresholds.
#'   This can be a one-based column index or a column name.
#' @param size_unit Unit for `size_col`. Supported values are `"auto"`,
#'   `"mm"`, `"um"`, and `"phi"`. `"auto"` treats finite positive values
#'   greater than or equal to 1000 as micrometres and otherwise treats values
#'   as millimetres. Explicit `"mm"` and `"um"` values override detection.
#' @param value_type Scale for sample values. Supported values are
#'   `"proportion"`, `"percent"`, and `"weight"`.
#' @param measurement_method Measurement method to store in the output. A
#'   single string is recycled to all rows.
#'
#' @return A `gsd_tbl` tibble with canonical columns including `sample_id`,
#'   `bin_id`, `raw_size_um`, `size_lower_um`, `size_upper_um`,
#'   `retained_percent`, `cum_finer_percent`, `cum_coarser_percent`,
#'   `is_open_lower`, `is_open_upper`, and `measurement_method`.
#' @export
read_gsd_wide <- function(file,
                          size_col = 1,
                          size_unit = "auto",
                          value_type = "percent",
                          measurement_method = NA_character_) {
  size_unit <- normalize_size_unit(size_unit)
  value_type <- match.arg(value_type, c("proportion", "percent", "weight"))

  x <- readr::read_csv(file, show_col_types = FALSE)
  if (ncol(x) < 2) {
    stop("Wide grain-size input must contain a size column and at least one sample column.", call. = FALSE)
  }

  size_col <- resolve_wide_size_col(size_col, x)
  sample_cols <- setdiff(names(x), size_col)
  parsed_sizes <- parse_wide_size_labels(x[[size_col]], size_unit)

  if (sum(parsed_sizes$terminal_fine) > 1) {
    stop("Wide grain-size input can contain at most one terminal fine row.", call. = FALSE)
  }

  if (any(parsed_sizes$terminal_fine) && !parsed_sizes$terminal_fine[nrow(x)]) {
    stop("The terminal fine row must be the final size row in wide grain-size input.", call. = FALSE)
  }

  long_rows <- lapply(sample_cols, function(sample_col) {
    tibble::tibble(
      sample_id = sample_col,
      size_um = parsed_sizes$raw_size_um,
      value = x[[sample_col]]
    )
  })
  long <- do.call(rbind, long_rows)
  rownames(long) <- NULL

  as_gsd_tbl(
    x = long,
    sample_col = "sample_id",
    size_col = "size_um",
    value_col = "value",
    size_unit = "um",
    value_type = value_type,
    measurement_method = measurement_method
  )
}
