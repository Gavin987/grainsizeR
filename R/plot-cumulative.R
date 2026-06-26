cumulative_x_values <- function(x, x_scale) {
  switch(
    x_scale,
    log10 = x$boundary_um,
    phi = x$boundary_phi,
    linear_um = x$boundary_um
  )
}

percentile_x_values <- function(x, x_scale) {
  switch(
    x_scale,
    log10 = x$grain_size_um,
    phi = x$grain_size_phi,
    linear_um = x$grain_size_um
  )
}

#' Plot cumulative grain-size curves
#'
#' `plot_cumulative()` plots finite-boundary cumulative grain-size curves from
#' `gs_cumulative()`.
#'
#' @param x A valid `gsd_tbl` object.
#' @param direction Cumulative direction to plot.
#' @param x_scale Display scale for the grain-size axis. `"log10"` and
#'   `"linear_um"` use micrometre grain-size values; `"phi"` uses phi units.
#' @param sample_id Optional character vector of sample identifiers to include.
#' @param show_percentiles Optional numeric vector of D-value percentiles to
#'   mark on the plot.
#' @param extrapolate Extrapolation behavior passed to `gs_d_values()` when
#'   `show_percentiles` is supplied.
#' @param facet_by_sample Should plots with multiple samples be faceted by
#'   sample? The default, `NULL`, facets when more than one sample is present.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examples
#' x <- data.frame(
#'   sample_id = "A",
#'   size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063),
#'   retained_proportion = c(0.05, 0.10, 0.25, 0.30, 0.20, 0.10)
#' )
#' gsd <- as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
#' plot_cumulative(gsd, x_scale = "log10")
#' plot_cumulative(gsd, x_scale = "phi", show_percentiles = c(10, 50, 90), extrapolate = "warn_linear")
plot_cumulative <- function(x,
                            direction = c("finer", "coarser"),
                            x_scale = c("log10", "phi", "linear_um"),
                            sample_id = NULL,
                            show_percentiles = NULL,
                            extrapolate = "error",
                            facet_by_sample = NULL) {
  validate_gsd_tbl(x)
  direction <- match.arg(direction)
  x_scale <- match.arg(x_scale)
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  plot_x <- plot_filter_samples(x, sample_id)
  curve <- gs_cumulative(plot_x)
  curve$x_value <- cumulative_x_values(curve, x_scale)
  curve$y_value <- if (direction == "finer") curve$percent_finer else curve$percent_coarser
  curve$sample_id <- as.character(curve$sample_id)
  if (is.null(facet_by_sample)) {
    facet_by_sample <- length(unique(curve$sample_id)) > 1
  }

  p <- ggplot2::ggplot(curve, ggplot2::aes(x = .data$x_value, y = .data$y_value, color = .data$sample_id, group = .data$sample_id)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::labs(x = .particle_size_axis_label(x_scale), y = paste("Percent", direction), color = "Sample") +
    ggplot2::theme_bw()

  if (x_scale == "log10") {
    p <- p + ggplot2::scale_x_log10(
      breaks = .log10_particle_breaks,
      labels = .format_particle_size_ticks
    )
  }

  if (!is.null(show_percentiles)) {
    percentiles <- gs_d_values(
      plot_x,
      probs = show_percentiles,
      interpolation_scale = if (x_scale == "linear_um") "linear_um" else "phi",
      output_unit = "um",
      extrapolate = extrapolate
    )
    percentiles$x_value <- percentile_x_values(percentiles, x_scale)
    percentiles$y_value <- if (direction == "finer") percentiles$percentile else 100 - percentiles$percentile
    percentiles$sample_id <- as.character(percentiles$sample_id)
    p <- p +
      ggplot2::geom_point(
        data = percentiles,
        ggplot2::aes(x = .data$x_value, y = .data$y_value, color = .data$sample_id),
        inherit.aes = FALSE,
        shape = 4
      )
  }
  if (isTRUE(facet_by_sample)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$sample_id))
  }

  p
}
