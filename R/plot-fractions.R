#' Plot grain-size fraction composition
#'
#' `plot_fractions()` plots fraction percentages from `gs_fractions()` as
#' stacked bars with one bar per sample.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scheme Built-in fraction scheme name passed to `gs_fractions()`.
#' @param normalize Normalization mode passed to `gs_fractions()`.
#' @param sample_id Optional character vector of sample identifiers to include.
#' @param fill_palette Fill palette. `"default"` uses ggplot2 defaults,
#'   `"YlOrBr"` uses `grDevices::hcl.colors()` with a yellow-orange-brown
#'   sequence, and `"none"` leaves the scale unchanged.
#' @param na_to_zero Should unresolved fraction percentages be plotted as zero?
#'   The default `FALSE` preserves `NA` values returned by `gs_fractions()`.
#'   Use `TRUE` to draw stacked bars without dropping components whose
#'   thresholds could not be resolved from the available grain-size classes.
#'   This affects only the plotted data and does not change the underlying
#'   `gs_fractions()` calculation.
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
#' plot_fractions(gsd, scheme = "gravel_sand_mud", fill_palette = "YlOrBr")
plot_fractions <- function(x,
                           scheme = "wentworth_major",
                           normalize = "none",
                           sample_id = NULL,
                           fill_palette = c("default", "YlOrBr", "none"),
                           na_to_zero = FALSE) {
  validate_gsd_tbl(x)
  fill_palette <- match.arg(fill_palette)
  if (!is.logical(na_to_zero) || length(na_to_zero) != 1 || is.na(na_to_zero)) {
    stop("`na_to_zero` must be `TRUE` or `FALSE`.", call. = FALSE)
  }
  plot_x <- plot_filter_samples(x, sample_id)
  fractions <- gs_fractions(plot_x, scheme = scheme, normalize = normalize)
  if (na_to_zero) {
    fractions$percent[is.na(fractions$percent)] <- 0
  }
  components <- scheme_components(scheme)
  component_levels <- components$component
  fractions$component <- factor(fractions$component, levels = component_levels)
  component_labels <- fraction_component_labels(component_levels)

  p <- ggplot2::ggplot(fractions, ggplot2::aes(x = .data$sample_id, y = .data$percent, fill = .data$component)) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Sample", y = "Percent", fill = "Component") +
    ggplot2::theme_bw()

  if (fill_palette == "YlOrBr") {
    colors <- grDevices::hcl.colors(length(component_levels), palette = "YlOrBr")
    names(colors) <- component_levels
    p <- p + ggplot2::scale_fill_manual(values = colors, breaks = component_levels, labels = component_labels)
  } else if (fill_palette == "default") {
    p <- p + ggplot2::scale_fill_discrete(breaks = component_levels, labels = component_labels)
  }

  p
}

fraction_component_labels <- function(component) {
  labels <- c(
    gravel = "Gravel",
    sand = "Sand",
    mud = "Mud",
    silt = "Silt",
    clay = "Clay",
    coarse_gravel = "Coarse gravel",
    medium_gravel = "Medium gravel",
    fine_gravel = "Fine gravel",
    very_fine_gravel = "Very fine gravel",
    very_coarse_sand = "Very coarse sand",
    coarse_sand = "Coarse sand",
    medium_sand = "Medium sand",
    fine_sand = "Fine sand",
    very_fine_sand = "Very fine sand",
    very_coarse_silt = "Very coarse silt",
    coarse_silt = "Coarse silt",
    medium_silt = "Medium silt",
    fine_silt = "Fine silt",
    very_fine_silt = "Very fine silt",
    clay = "Clay"
  )
  out <- unname(labels[component])
  missing <- is.na(out)
  out[missing] <- gsub("_", " ", component[missing])
  out
}
