#' Plot grain-size fraction composition
#'
#' `plot_fractions()` plots fraction percentages from `gs_fractions()` as
#' stacked bars with one bar per sample.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scheme Built-in fraction scheme name passed to `gs_fractions()`.
#' @param normalize Normalization mode passed to `gs_fractions()`.
#' @param sample_id Optional character vector of sample identifiers to include.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examples
#' x <- data.frame(
#'   sample_id = c("A", "A", "A", "B", "B", "B"),
#'   size_mm = rep(c(2, 0.5, 0.063), 2),
#'   retained_proportion = c(0.20, 0.50, 0.30, 0.10, 0.60, 0.30)
#' )
#' gsd <- as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
#' plot_fractions(gsd, scheme = "wentworth_major")
plot_fractions <- function(x,
                           scheme = "wentworth_major",
                           normalize = "none",
                           sample_id = NULL) {
  validate_gsd_tbl(x)
  plot_x <- plot_filter_samples(x, sample_id)
  fractions <- gs_fractions(plot_x, scheme = scheme, normalize = normalize)

  ggplot2::ggplot(fractions, ggplot2::aes(x = .data$sample_id, y = .data$percent, fill = .data$component)) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Sample", y = "Percent", fill = "Component")
}
