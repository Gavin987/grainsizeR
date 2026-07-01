plot_sample_ids <- function(x) {
  unique(as.character(x$sample_id))
}

format_available_sample_ids <- function(sample_ids, max_ids = 5) {
  shown <- utils::head(sample_ids, max_ids)
  suffix <- if (length(sample_ids) > max_ids) ", ..." else ""
  paste0(paste(shown, collapse = ", "), suffix)
}

resolve_plot_sample <- function(x, sample = NULL, sample_id = NULL) {
  if (!is.null(sample) && !is.null(sample_id)) {
    stop("Use either `sample` or `sample_id`, not both.", call. = FALSE)
  }
  selection <- if (!is.null(sample)) sample else sample_id
  if (is.null(selection)) {
    return(NULL)
  }

  sample_ids <- plot_sample_ids(x)
  if (is.numeric(selection)) {
    if (any(is.na(selection)) || any(selection != floor(selection))) {
      stop("Numeric `sample` values must be whole-number sample indices.", call. = FALSE)
    }
    if (any(selection < 1 | selection > length(sample_ids))) {
      stop(
        "Sample index out of range. Available sample indices are 1 to ",
        length(sample_ids), ".",
        call. = FALSE
      )
    }
    return(sample_ids[selection])
  }

  selection <- as.character(selection)
  missing <- setdiff(selection, sample_ids)
  if (length(missing) > 0) {
    stop(
      "Sample ID not found: ", paste(missing, collapse = ", "),
      ". Available sample IDs include: ", format_available_sample_ids(sample_ids), ".",
      call. = FALSE
    )
  }
  selection
}

plot_filter_samples <- function(x, sample_id = NULL, sample = NULL) {
  selected <- resolve_plot_sample(x, sample = sample, sample_id = sample_id)
  if (is.null(selected)) {
    return(x)
  }

  out <- x[as.character(x$sample_id) %in% selected, ]
  if (nrow(out) == 0) {
    stop("No matching samples were found.", call. = FALSE)
  }
  out
}

.require_single_plot_sample <- function(x, function_name) {
  samples <- unique(as.character(x$sample_id))
  if (length(samples) != 1) {
    stop(
      "`", function_name, "()` plots one sample at a time. ",
      "Use `sample` or `sample_id` to select one sample, filter `x` before plotting, ",
      "or loop over samples and arrange the returned plots externally.",
      call. = FALSE
    )
  }
  samples
}

normalize_particle_unit <- function(particle_unit) {
  particle_unit <- match.arg(particle_unit, c("mm", "um", "milli", "micro"))
  switch(
    particle_unit,
    milli = "mm",
    micro = "um",
    particle_unit
  )
}

particle_unit_divisor <- function(particle_unit) {
  switch(
    particle_unit,
    mm = 1000,
    um = 1
  )
}

.open_tail_plot_size_um <- function() {
  1.5
}

.plot_size_um <- function(x) {
  out <- x$raw_size_um
  lower_tail <- x$is_open_lower
  out[lower_tail] <- .open_tail_plot_size_um()
  out
}

distribution_x_values <- function(x, x_scale, particle_unit = "mm") {
  plot_size_um <- .plot_size_um(x)
  switch(
    x_scale,
    log10 = plot_size_um / particle_unit_divisor(particle_unit),
    phi = um_to_phi(plot_size_um),
    linear_um = plot_size_um
  )
}

.prepare_distribution_plot_data <- function(x,
                                            x_scale,
                                            particle_unit = "mm",
                                            sample_id = NULL,
                                            sample = NULL,
                                            show_open_ends = TRUE) {
  plot_data <- plot_filter_samples(x, sample_id = sample_id, sample = sample)
  if (!show_open_ends) {
    plot_data <- plot_data[!plot_data$is_open_lower & !plot_data$is_open_upper, ]
  }
  if (nrow(plot_data) == 0) {
    stop("No grain-size classes are available to plot.", call. = FALSE)
  }

  plot_data$size_original_um <- plot_data$raw_size_um
  plot_data$size_plot <- distribution_x_values(plot_data, x_scale, particle_unit = particle_unit)
  plot_data$x_value <- plot_data$size_plot
  plot_data$particle_unit <- if (x_scale == "log10") particle_unit else NA_character_
  plot_data$percent <- plot_data$retained_percent
  plot_data$sample_id <- as.character(plot_data$sample_id)
  plot_data
}

.log10_particle_breaks <- function(particle_unit = "mm") {
  force(particle_unit)
  function(limits) {
    if (particle_unit == "mm") {
      c(0.001, 0.01, 0.1, 1, 10)
    } else {
      c(1, 10, 100, 1000, 10000)
    }
  }
}

.log10_particle_minor_breaks <- function(particle_unit = "mm") {
  force(particle_unit)
  function(limits) {
    major <- .log10_particle_breaks(particle_unit)(limits)
    as.vector(outer(1:9, major, `*`))
  }
}

.log10_particle_limits <- function(particle_unit = "mm") {
  if (particle_unit == "mm") {
    c(0.001, 10)
  } else {
    c(1, 10000)
  }
}

.format_particle_size_ticks <- function(x) {
  out <- format(x, scientific = FALSE, trim = TRUE)
  out <- sub("(\\.\\d*?)0+$", "\\1", out)
  out <- sub("\\.$", "", out)
  out[is.na(x)] <- NA_character_
  out
}

.particle_size_axis_label <- function(x_scale, particle_unit = "mm") {
  switch(
    x_scale,
    log10 = paste0("Particle size (", particle_unit, ")"),
    phi = "Particle size (phi)",
    linear_um = "Particle size (um)"
  )
}

#' Plot retained grain-size distributions
#'
#' `plot_distribution()` plots retained grain-size percentages by particle-size
#' class. Metric displays center bars on the original particle-size class
#' values after unit conversion, with lower open-ended classes displayed at
#' 0.0015 mm for plotting only.
#'
#' @param x A valid `gsd_tbl` object.
#' @param x_scale Display scale for the grain-size axis. `"log10"` uses
#'   grain-size values in `particle_unit`; `"linear_um"` uses micrometre
#'   values; `"phi"` uses phi units.
#' @param type Plot type: `"bar"` or `"line"`.
#' @param particle_unit Particle-size unit for `x_scale = "log10"`.
#'   Preferred values are `"mm"` for millimetres and `"um"` for micrometres.
#'   Aliases `"milli"` and `"micro"` are also accepted.
#' @param sample Optional sample selector. A character value selects by sample
#'   ID; a numeric value selects by one-based sample index using the order in
#'   which samples appear in `x`.
#' @param sample_id Optional character vector of sample identifiers to include.
#'   Kept for backward compatibility; use `sample` for new code.
#' @param show_open_ends Should open-ended classes be included using raw size
#'   labels as plotting proxies?
#' @param cumulative Should a cumulative percent-finer line be overlaid on the
#'   retained-size bars? This combined display is useful for GRADISTAT-style
#'   grain-size summaries.
#' @param facet_by_sample Ignored compatibility argument. Distribution plots
#'   are single-sample displays; use `sample` or `sample_id` to select one
#'   sample, loop over samples, or arrange returned plots externally with
#'   another plotting package.
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
#' plot_distribution(gsd, sample = 1)
#' plot_distribution(gsd, cumulative = TRUE)
#' plot_distribution(gsd, x_scale = "phi", type = "line")
plot_distribution <- function(x,
                              x_scale = c("log10", "phi", "linear_um"),
                              type = c("bar", "line"),
                              particle_unit = c("mm", "um", "milli", "micro"),
                              sample = NULL,
                              sample_id = NULL,
                              show_open_ends = TRUE,
                              cumulative = FALSE,
                              facet_by_sample = NULL) {
  validate_gsd_tbl(x)
  x_scale <- match.arg(x_scale)
  type <- match.arg(type)
  particle_unit <- normalize_particle_unit(particle_unit)

  plot_data <- .prepare_distribution_plot_data(
    x,
    x_scale = x_scale,
    particle_unit = particle_unit,
    sample_id = sample_id,
    sample = sample,
    show_open_ends = show_open_ends
  )
  .require_single_plot_sample(plot_data, "plot_distribution")

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$x_value, y = .data$retained_percent))
  if (type == "bar") {
    p <- p + ggplot2::geom_col(fill = "grey75", color = "black", linewidth = 0.25)
  } else {
    p <- p + ggplot2::geom_line(linewidth = 0.7, color = "black") +
      ggplot2::geom_point(color = "black", size = 1.3)
  }

  if (isTRUE(cumulative)) {
    curve <- .prepare_cumulative_plot_data(
      x,
      x_scale = x_scale,
      particle_unit = particle_unit,
      sample_id = sample_id,
      sample = sample
    )
    .require_single_plot_sample(curve, "plot_distribution")
    p <- p +
      ggplot2::geom_line(
        data = curve,
        ggplot2::aes(x = .data$x_value, y = .data$percent_finer),
        inherit.aes = FALSE,
        linewidth = 1.1,
        color = "black"
      ) +
      ggplot2::geom_point(
        data = curve,
        ggplot2::aes(x = .data$x_value, y = .data$percent_finer),
        inherit.aes = FALSE,
        size = 1.2,
        color = "black"
      )
  }

  p <- p +
    ggplot2::labs(x = .particle_size_axis_label(x_scale, particle_unit = particle_unit), y = "Percent") +
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
  p
}
