cumulative_x_values <- function(x, x_scale, particle_unit = "mm") {
  switch(
    x_scale,
    log10 = x$boundary_um / particle_unit_divisor(particle_unit),
    phi = x$boundary_phi,
    linear_um = x$boundary_um
  )
}

percentile_x_values <- function(x, x_scale, particle_unit = "mm") {
  switch(
    x_scale,
    log10 = x$grain_size_um / particle_unit_divisor(particle_unit),
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
#' @param x_scale Display scale for the grain-size axis. `"log10"` uses
#'   grain-size values in `particle_unit`; `"linear_um"` uses micrometre
#'   values; `"phi"` uses phi units.
#' @param particle_unit Particle-size unit for `x_scale = "log10"`.
#'   Preferred values are `"mm"` for millimetres and `"um"` for micrometres.
#'   Aliases `"milli"` and `"micro"` are also accepted.
#' @param sample_id Optional character vector of sample identifiers to include.
#' @param show_percentiles Optional numeric vector of D-value percentiles to
#'   mark on the plot.
#' @param extrapolate Extrapolation behavior passed to `gs_d_values()` when
#'   `show_percentiles` is supplied.
#' @param facet_by_sample Deprecated. Cumulative plots are single-sample
#'   displays; use `sample_id` to select one sample, loop over samples, or
#'   arrange returned plots externally with another plotting package.
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
                            particle_unit = c("mm", "um", "milli", "micro"),
                            sample_id = NULL,
                            show_percentiles = NULL,
                            extrapolate = "error",
                            facet_by_sample = NULL) {
  validate_gsd_tbl(x)
  direction <- match.arg(direction)
  x_scale <- match.arg(x_scale)
  particle_unit <- normalize_particle_unit(particle_unit)
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  plot_x <- plot_filter_samples(x, sample_id)
  curve <- gs_cumulative(plot_x)
  curve$x_value <- cumulative_x_values(curve, x_scale, particle_unit = particle_unit)
  curve$y_value <- if (direction == "finer") curve$percent_finer else curve$percent_coarser
  curve$sample_id <- as.character(curve$sample_id)
  .require_single_plot_sample(curve, "plot_cumulative")

  p <- ggplot2::ggplot(curve, ggplot2::aes(x = .data$x_value, y = .data$y_value)) +
    ggplot2::geom_line(linewidth = 1.1, color = "black") +
    ggplot2::geom_point(size = 1.2, color = "black") +
    ggplot2::labs(x = .particle_size_axis_label(x_scale, particle_unit = particle_unit), y = paste("Percent", direction)) +
    ggplot2::coord_cartesian(ylim = c(0, 100)) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.grid.minor.y = ggplot2::element_blank())

  if (x_scale == "log10") {
    p <- p + ggplot2::scale_x_log10(
      limits = .log10_particle_limits(particle_unit),
      breaks = .log10_particle_breaks(particle_unit),
      minor_breaks = .log10_particle_minor_breaks(particle_unit),
      labels = .format_particle_size_ticks,
      expand = ggplot2::expansion(mult = 0)
    ) +
      ggplot2::annotation_logticks(sides = "b")
  }

  if (!is.null(show_percentiles)) {
    percentiles <- gs_d_values(
      plot_x,
      probs = show_percentiles,
      interpolation_scale = if (x_scale == "linear_um") "linear_um" else "phi",
      output_unit = "um",
      extrapolate = extrapolate
    )
    percentiles$x_value <- percentile_x_values(percentiles, x_scale, particle_unit = particle_unit)
    percentiles$y_value <- if (direction == "finer") percentiles$percentile else 100 - percentiles$percentile
    percentiles$sample_id <- as.character(percentiles$sample_id)
    p <- p +
      ggplot2::geom_point(
        data = percentiles,
        ggplot2::aes(x = .data$x_value, y = .data$y_value),
        inherit.aes = FALSE,
        shape = 4,
        color = "black"
      )
  }

  p
}
