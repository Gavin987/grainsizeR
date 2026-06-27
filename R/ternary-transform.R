#' Convert ternary coordinates to Cartesian coordinates
#'
#' `ternary_to_xy()` converts left, right, and top ternary percentages to
#' Cartesian coordinates for an equilateral triangle. The transformation uses
#' public-domain triangle geometry and does not depend on external texture
#' classification data.
#'
#' @param left Numeric vector for the left-axis component.
#' @param right Numeric vector for the right-axis component.
#' @param top Numeric vector for the top-axis component.
#' @param normalize Should rows be normalized so `left + right + top = 100`?
#'
#' @return A tibble with Cartesian coordinates and normalized ternary values.
#' @export
ternary_to_xy <- function(left, right, top, normalize = TRUE) {
  if (!is.numeric(left) || !is.numeric(right) || !is.numeric(top)) {
    stop("`left`, `right`, and `top` must be numeric vectors.", call. = FALSE)
  }

  n <- max(length(left), length(right), length(top))
  left <- rep(left, length.out = n)
  right <- rep(right, length.out = n)
  top <- rep(top, length.out = n)

  if (anyNA(left) || anyNA(right) || anyNA(top)) {
    stop("Ternary component values must not be missing.", call. = FALSE)
  }

  if (normalize) {
    total <- left + right + top
    if (any(total <= 0)) {
      stop("Ternary component totals must be positive when `normalize = TRUE`.", call. = FALSE)
    }
    left <- left / total * 100
    right <- right / total * 100
    top <- top / total * 100
  }

  right_prop <- right / 100
  top_prop <- top / 100

  tibble::tibble(
    x = right_prop + 0.5 * top_prop,
    y = sqrt(3) / 2 * top_prop,
    left = left,
    right = right,
    top = top
  )
}

.ternary_cartesian_theme <- function() {
  ggplot2::theme(
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank()
  )
}

.ternary_axis_guides <- function(left = "Left",
                                 right = "Right",
                                 top = "Top",
                                 tick_values = seq(0, 100, by = 20)) {
  height <- sqrt(3) / 2
  ticks <- tick_values[tick_values >= 0 & tick_values <= 100]
  p <- ticks / 100

  titles <- data.frame(
    axis = c("left", "right", "top"),
    label = c(left, right, top),
    x = c(-0.055, 1.055, 0.5),
    y = c(-0.055, -0.055, height + 0.055),
    angle = c(0, 0, 0),
    stringsAsFactors = FALSE
  )

  tick_data <- rbind(
    data.frame(
      axis = "left",
      label = as.character(ticks),
      x = 1 - p,
      y = -0.035,
      angle = 0,
      stringsAsFactors = FALSE
    ),
    data.frame(
      axis = "right",
      label = as.character(ticks),
      x = 1 - 0.5 * p + 0.035,
      y = height * p,
      angle = -60,
      stringsAsFactors = FALSE
    ),
    data.frame(
      axis = "top",
      label = as.character(ticks),
      x = 0.5 * p - 0.035,
      y = height * p,
      angle = 60,
      stringsAsFactors = FALSE
    )
  )

  list(titles = titles, ticks = tick_data)
}

.usda_ternary_axis_guides <- function(tick_values = seq(10, 100, by = 10)) {
  height <- sqrt(3) / 2
  ticks <- tick_values[tick_values > 0 & tick_values <= 100]
  p <- ticks / 100

  list(
    titles = data.frame(
      axis = c("sand", "silt", "clay"),
      label = c("percent sand", "percent silt", "percent clay"),
      x = c(0.5, 0.9, 0.1),
      y = c(-0.145, 0.43, 0.43),
      angle = c(0, -60, 60),
      stringsAsFactors = FALSE
    ),
    ticks = rbind(
      data.frame(
        axis = "sand",
        label = as.character(ticks),
        x = 1 - p,
        y = -0.035,
        angle = 0,
        stringsAsFactors = FALSE
      ),
      data.frame(
        axis = "silt",
        label = as.character(ticks),
        x = 0.5 + 0.5 * p + 0.035,
        y = height * (1 - p),
        angle = -60,
        stringsAsFactors = FALSE
      ),
      data.frame(
        axis = "clay",
        label = as.character(ticks),
        x = 0.5 * p - 0.035,
        y = height * p,
        angle = 60,
        stringsAsFactors = FALSE
      )
    )
  )
}

.gradistat_ternary_axis_guides <- function(basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel")) {
  basis <- match.arg(basis)
  if (basis != "gravel_sand_mud") {
    return(.ternary_axis_guides(left = "Sand", right = "Silt", top = "Clay"))
  }

  height <- sqrt(3) / 2
  gravel_ticks <- c(0, 5, 30, 80, 100)
  p <- gravel_ticks / 100
  list(
    titles = data.frame(
      axis = c("left", "right", "top", "gravel_axis", "ratio_axis"),
      label = c("Mud", "Sand", "Gravel", "% gravel", "sand/mud ratio"),
      x = c(-0.055, 1.055, 0.5, 0.18, 0.5),
      y = c(-0.055, -0.055, height + 0.055, 0.45, -0.095),
      angle = c(0, 0, 0, 60, 0),
      stringsAsFactors = FALSE
    ),
    ticks = rbind(
      data.frame(
        axis = "gravel",
        label = as.character(gravel_ticks),
        x = 0.5 * p - 0.035,
        y = height * p,
        angle = 60,
        stringsAsFactors = FALSE
      ),
      data.frame(
        axis = "sand_mud_ratio",
        label = c("1:9", "5:5", "9:1"),
        x = c(0.1, 0.5, 0.9),
        y = c(-0.035, -0.035, -0.035),
        angle = 0,
        stringsAsFactors = FALSE
      )
    )
  )
}

.add_ternary_axis_guides <- function(p, guides, title_size = 3.4, tick_size = 2.7) {
  p +
    ggplot2::geom_text(
      data = guides$titles,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label, angle = .data$angle),
      inherit.aes = FALSE,
      fontface = "bold",
      size = title_size
    ) +
    ggplot2::geom_text(
      data = guides$ticks,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label, angle = .data$angle),
      inherit.aes = FALSE,
      size = tick_size,
      color = "grey30"
    )
}
