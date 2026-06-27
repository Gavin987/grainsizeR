cumulative_x_values <- function(x, x_scale, particle_unit = "mm") {
  switch(
    x_scale,
    log10 = x$boundary_um / particle_unit_divisor(particle_unit),
    phi = x$boundary_phi,
    linear_um = x$boundary_um
  )
}

.prepare_cumulative_plot_data <- function(x, x_scale, particle_unit = "mm", sample_id = NULL) {
  plot_x <- plot_filter_samples(x, sample_id)
  curve <- gs_cumulative(plot_x)

  lower_tail <- plot_x[plot_x$is_open_lower, , drop = FALSE]
  if (nrow(lower_tail) > 0) {
    lower_tail <- lower_tail[order(lower_tail$sample_id, lower_tail$bin_id), , drop = FALSE]
    lower_tail <- lower_tail[!duplicated(lower_tail$sample_id, fromLast = TRUE), , drop = FALSE]
    tail_curve <- tibble::tibble(
      sample_id = lower_tail$sample_id,
      boundary_id = max(curve$boundary_id, 0, na.rm = TRUE) + seq_len(nrow(lower_tail)),
      boundary_um = .open_tail_plot_size_um(),
      boundary_mm = um_to_mm(.open_tail_plot_size_um()),
      boundary_phi = um_to_phi(.open_tail_plot_size_um()),
      percent_finer = lower_tail$cum_finer_percent,
      percent_coarser = lower_tail$cum_coarser_percent
    )
    curve <- rbind(as.data.frame(curve), as.data.frame(tail_curve))
    curve <- curve[order(curve$sample_id, curve$boundary_um), , drop = FALSE]
    curve <- tibble::as_tibble(curve)
  }

  curve$x_value <- cumulative_x_values(curve, x_scale, particle_unit = particle_unit)
  curve
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
#' `plot_cumulative()` plots cumulative grain-size curves from `gs_cumulative()`.
#' Lower open-ended classes are displayed at 0.002 mm for plotting only.
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
  curve <- .prepare_cumulative_plot_data(x, x_scale, particle_unit = particle_unit, sample_id = sample_id)
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
