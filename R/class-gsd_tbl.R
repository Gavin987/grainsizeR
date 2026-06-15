gsd_tbl_columns <- c(
  "sample_id",
  "bin_id",
  "raw_size_um",
  "size_lower_um",
  "size_upper_um",
  "size_mid_um",
  "size_mid_phi",
  "retained_percent",
  "cum_finer_percent",
  "cum_coarser_percent",
  "is_open_lower",
  "is_open_upper",
  "measurement_method"
)

new_gsd_tbl <- function(x) {
  x <- tibble::as_tibble(x)
  missing_cols <- setdiff(gsd_tbl_columns, names(x))

  if (length(missing_cols) > 0) {
    stop(
      "A gsd_tbl is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  x <- x[gsd_tbl_columns]
  class(x) <- c("gsd_tbl", setdiff(class(x), "gsd_tbl"))
  x
}

#' Test whether an object is a grain-size distribution tibble
#'
#' @param x An object to test.
#'
#' @return `TRUE` if `x` inherits from `gsd_tbl`, otherwise `FALSE`.
#' @export
is_gsd_tbl <- function(x) {
  inherits(x, "gsd_tbl")
}
