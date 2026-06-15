#' Build cumulative grain-size boundary curves
#'
#' `gs_cumulative()` converts retained class data in a `gsd_tbl` into finite
#' class-boundary cumulative curves. The returned table contains one row per
#' finite boundary in each sample.
#'
#' @param x A valid `gsd_tbl` object.
#'
#' @return A tibble with sample identifiers, finite grain-size boundaries, and
#'   cumulative percent finer and coarser values at each boundary.
#' @export
gs_cumulative <- function(x) {
  validate_gsd_tbl(x)

  split_data <- split(x, x$sample_id, drop = TRUE)
  curves <- lapply(split_data, cumulative_one_sample)
  out <- do.call(rbind, unname(curves))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

cumulative_one_sample <- function(sample_data) {
  sample_data <- sample_data[order(sample_data$bin_id), ]
  finite <- !sample_data$is_open_lower
  boundaries_um <- sample_data$raw_size_um[finite]

  tibble::tibble(
    sample_id = sample_data$sample_id[finite],
    boundary_id = seq_along(boundaries_um),
    boundary_um = boundaries_um,
    boundary_mm = um_to_mm(boundaries_um),
    boundary_phi = um_to_phi(boundaries_um),
    percent_finer = sample_data$cum_finer_percent[finite],
    percent_coarser = sample_data$cum_coarser_percent[finite]
  )
}
