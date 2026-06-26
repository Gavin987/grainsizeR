plot_filter_samples <- function(x, sample_id) {
  if (is.null(sample_id)) {
    return(x)
  }

  out <- x[x$sample_id %in% sample_id, ]
  if (nrow(out) == 0) {
    stop("No matching samples were found.", call. = FALSE)
  }
  out
}

distribution_x_values <- function(x, x_scale) {
  proxy_um <- ifelse(is.na(x$size_mid_um), x$raw_size_um, x$size_mid_um)
  switch(
    x_scale,
    log10 = proxy_um,
    phi = ifelse(is.na(x$size_mid_phi), um_to_phi(x$raw_size_um), x$size_mid_phi),
    linear_um = proxy_um
  )
}

.log10_particle_breaks <- function(limits) {
  limits <- limits[is.finite(limits) & limits > 0]
  if (length(limits) == 0) {
    return(c(1, 10, 100, 1000, 10000))
  }
  powers <- floor(log10(min(limits))):ceiling(log10(max(limits)))
  10^powers
}

.format_particle_size_ticks <- function(x) {
  out <- format(x, scientific = FALSE, trim = TRUE)
  out[is.na(x)] <- NA_character_
  out
}

.particle_size_axis_label <- function(x_scale) {
  switch(
    x_scale,
    log10 = "Particle size (um)",
    phi = "Particle size (phi)",
    linear_um = "Particle size (um)"
  )
}

#' Plot retained grain-size distributions
#'
#' `plot_distribution()` plots retained grain-size percentages by class. Closed
#' classes are plotted at class midpoints. When `show_open_ends = TRUE`,
#' open-ended classes are plotted at their raw size labels as a display proxy.
#'
#' @param x A valid `gsd_tbl` object.
#' @param x_scale Display scale for the grain-size axis. `"log10"` and
#'   `"linear_um"` use micrometre grain-size values; `"phi"` uses phi units.
#' @param type Plot type: `"bar"` or `"line"`.
#' @param sample_id Optional character vector of sample identifiers to include.
#' @param show_open_ends Should open-ended classes be included using raw size
#'   labels as plotting proxies?
#' @param cumulative Should a cumulative percent-finer line be overlaid on the
#'   retained-size bars? This combined display is useful for GRADISTAT-style
#'   grain-size summaries.
#' @param facet_by_sample Should plots with multiple samples be faceted by
#'   sample? The default, `NULL`, facets when more than one sample is present.
#'
#' @return A `ggplot` object.
#' @importFrom rlang .data
#' @export
#'
#' @examples
#' x <- data.frame(
#'   sample_id = "A",
#'   size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063),
#'   retained_proportion = c(0.05, 0.10, 0.25, 0.30, 0.20, 0.10)
#' )
#' gsd <- as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
#' plot_distribution(gsd, x_scale = "log10")
#' plot_distribution(gsd, cumulative = TRUE)
#' plot_distribution(gsd, x_scale = "phi", type = "line")
plot_distribution <- function(x,
                              x_scale = c("log10", "phi", "linear_um"),
                              type = c("bar", "line"),
                              sample_id = NULL,
                              show_open_ends = TRUE,
                              cumulative = FALSE,
                              facet_by_sample = NULL) {
  validate_gsd_tbl(x)
  x_scale <- match.arg(x_scale)
  type <- match.arg(type)

  plot_data <- plot_filter_samples(x, sample_id)
  if (!show_open_ends) {
    plot_data <- plot_data[!plot_data$is_open_lower & !plot_data$is_open_upper, ]
  }
  if (nrow(plot_data) == 0) {
    stop("No grain-size classes are available to plot.", call. = FALSE)
  }

  plot_data$x_value <- distribution_x_values(plot_data, x_scale)
  plot_data$sample_id <- as.character(plot_data$sample_id)
  if (is.null(facet_by_sample)) {
    facet_by_sample <- length(unique(plot_data$sample_id)) > 1
  }

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$x_value, y = .data$retained_percent))
  if (type == "bar") {
    p <- p + ggplot2::geom_col(ggplot2::aes(fill = .data$sample_id), position = "dodge")
  } else {
    p <- p + ggplot2::geom_line(ggplot2::aes(color = .data$sample_id, group = .data$sample_id)) +
      ggplot2::geom_point(ggplot2::aes(color = .data$sample_id))
  }

  if (isTRUE(cumulative)) {
    curve <- gs_cumulative(plot_filter_samples(x, sample_id))
    curve$x_value <- cumulative_x_values(curve, x_scale)
    p <- p +
      ggplot2::geom_line(
        data = curve,
        ggplot2::aes(x = .data$x_value, y = .data$percent_finer, color = .data$sample_id, group = .data$sample_id),
        inherit.aes = FALSE,
        linewidth = 0.8
      ) +
      ggplot2::geom_point(
        data = curve,
        ggplot2::aes(x = .data$x_value, y = .data$percent_finer, color = .data$sample_id),
        inherit.aes = FALSE,
        size = 1.4
      )
  }

  p <- p +
    ggplot2::labs(x = .particle_size_axis_label(x_scale), y = "Percent", fill = "Sample", color = "Sample") +
    ggplot2::coord_cartesian(ylim = c(0, 100)) +
    ggplot2::theme_bw()
  if (x_scale == "log10") {
    p <- p + ggplot2::scale_x_log10(
      breaks = .log10_particle_breaks,
      labels = .format_particle_size_ticks
    )
  }
  if (isTRUE(facet_by_sample)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$sample_id))
  }
  p
}
