select_gradistat_sample <- function(x, sample_id) {
  sample_ids <- unique(as.character(x$sample_id))
  if (is.null(sample_id)) {
    if (length(sample_ids) != 1) {
      stop("`sample_id` must be supplied when `x` contains multiple samples.", call. = FALSE)
    }
    sample_id <- sample_ids
  }
  if (length(sample_id) != 1) {
    stop("`sample_id` must identify exactly one sample.", call. = FALSE)
  }

  out <- x[as.character(x$sample_id) == sample_id, ]
  if (nrow(out) == 0) {
    stop("No matching sample was found for `sample_id`.", call. = FALSE)
  }
  out
}

gradistat_axis_values <- function(x, x_scale) {
  switch(
    x_scale,
    phi = x$grain_size_phi,
    log10 = x$grain_size_um,
    linear_um = x$grain_size_um
  )
}

gradistat_boundary_axis_values <- function(x, x_scale) {
  switch(
    x_scale,
    phi = um_to_phi(x$boundary_um),
    log10 = x$boundary_um,
    linear_um = x$boundary_um
  )
}

gradistat_fraction_boundaries <- function(fractions, x_scale) {
  boundaries <- sort(unique(c(
    fractions$lower_um[is.finite(fractions$lower_um) & fractions$lower_um > 0],
    fractions$upper_um[is.finite(fractions$upper_um) & fractions$upper_um > 0]
  )))
  if (length(boundaries) == 0) {
    return(tibble::tibble(boundary_um = numeric(), x_value = numeric()))
  }
  tibble::tibble(
    boundary_um = boundaries,
    x_value = switch(
      x_scale,
      phi = um_to_phi(boundaries),
      log10 = boundaries,
      linear_um = boundaries
    )
  )
}

safe_gradistat_component <- function(expr, label) {
  tryCatch(
    expr,
    error = function(err) {
      warning(label, " could not be calculated: ", conditionMessage(err), call. = FALSE)
      NULL
    }
  )
}

format_gradistat_number <- function(x, digits = 3) {
  if (length(x) == 0) {
    return(character())
  }
  out <- format(signif(x, digits), trim = TRUE)
  out[is.na(x)] <- "NA"
  out
}

gradistat_caption <- function(d_values, fractions, folk_ward, indices) {
  parts <- character()

  if (!is.null(d_values)) {
    d50 <- d_values$grain_size_um[d_values$percentile == 50][1]
    parts <- c(parts, paste0("D50 = ", format_gradistat_number(d50), " um"))
  }

  if (!is.null(folk_ward)) {
    parts <- c(parts, paste0(
      "Folk & Ward: mean = ", format_gradistat_number(folk_ward$mean_fw_phi[1]), " phi",
      ", sorting = ", format_gradistat_number(folk_ward$sorting_fw_phi[1]),
      ", skewness = ", format_gradistat_number(folk_ward$skewness_fw[1]),
      ", kurtosis = ", format_gradistat_number(folk_ward$kurtosis_fw[1])
    ))
  }

  if (!is.null(fractions)) {
    resolved <- fractions[!is.na(fractions$percent), ]
    if (nrow(resolved) > 0) {
      fraction_text <- paste0(
        resolved$component,
        " ",
        format_gradistat_number(resolved$percent),
        "%"
      )
      parts <- c(parts, paste(fraction_text, collapse = "; "))
    }
  }

  if (!is.null(indices)) {
    parts <- c(parts, paste0(
      "Cu = ", format_gradistat_number(indices$Cu[1]),
      "; Cc = ", format_gradistat_number(indices$Cc[1])
    ))
  }

  paste(parts, collapse = "\n")
}

gradistat_summary_data_internal <- function(x,
                                            sample_id = NULL,
                                            x_scale = c("phi", "log10", "linear_um"),
                                            fraction_scheme = "gradistat",
                                            d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
                                            interpolation_scale = "phi",
                                            extrapolate = "error") {
  validate_gsd_tbl(x)
  x_scale <- match.arg(x_scale)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  sample_x <- select_gradistat_sample(x, sample_id)
  selected_id <- unique(as.character(sample_x$sample_id))[1]

  distribution <- sample_x
  distribution$x_value <- distribution_x_values(distribution, x_scale)
  distribution$sample_id <- as.character(distribution$sample_id)

  cumulative <- gs_cumulative(sample_x)
  cumulative$x_value <- cumulative_x_values(cumulative, x_scale)

  d_table <- safe_gradistat_component(
    gs_d_values(
      sample_x,
      probs = d_values,
      interpolation_scale = interpolation_scale,
      output_unit = "um",
      extrapolate = extrapolate
    ),
    "D-values"
  )
  if (!is.null(d_table)) {
    d_table$x_value <- percentile_x_values(d_table, x_scale)
  }

  fractions <- safe_gradistat_component(
    gs_fractions(
      sample_x,
      scheme = fraction_scheme,
      interpolation_scale = interpolation_scale,
      unresolved = "warn_na",
      extrapolate = extrapolate
    ),
    "Fractions"
  )

  folk_ward <- safe_gradistat_component(
    gs_folk_ward(
      sample_x,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    ),
    "Folk and Ward statistics"
  )

  indices <- safe_gradistat_component(
    gs_grain_size_indices(
      sample_x,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    ),
    "Grain-size indices"
  )

  list(
    sample_id = selected_id,
    distribution = tibble::as_tibble(distribution),
    cumulative = tibble::as_tibble(cumulative),
    d_values = d_table,
    fractions = fractions,
    folk_ward = folk_ward,
    indices = indices,
    fraction_boundaries = if (is.null(fractions)) {
      tibble::tibble(boundary_um = numeric(), x_value = numeric())
    } else {
      gradistat_fraction_boundaries(fractions, x_scale)
    },
    summary_caption = gradistat_caption(d_table, fractions, folk_ward, indices)
  )
}

#' Plot a GRADISTAT-inspired grain-size summary
#'
#' `plot_gradistat_summary()` creates an original, report-oriented sediment
#' grain-size diagnostic plot for one sample. It combines retained distribution
#' bars, a cumulative percent-finer curve, optional D-value markers, optional
#' fraction boundaries, and a compact caption of summary statistics.
#'
#' The function is inspired by common sediment grain-size reporting needs and by
#' the type of summary output often associated with GRADISTAT workflows. It is
#' not GRADISTAT software, does not reproduce the GRADISTAT workbook layout, and
#' does not copy GRADISTAT code, tables, data, or plot templates.
#'
#' @param x A valid `gsd_tbl` object.
#' @param sample_id Sample identifier. Required when `x` contains multiple
#'   samples.
#' @param x_scale Display scale for the grain-size axis. `"phi"` uses phi units
#'   with coarser sizes on the left and finer sizes on the right. `"log10"`
#'   uses a log10 micrometer axis. `"linear_um"` uses a linear micrometer axis.
#' @param fraction_scheme Built-in fraction scheme used for fraction boundaries
#'   and summary percentages.
#' @param d_values Numeric vector of D-value percentiles to mark. Marked
#'   D-values falling on a plateau caused by consecutive zero-retained
#'   classes are placed using `gs_d_values()`'s deterministic tie-breaking
#'   rule (see its documentation).
#' @param show_distribution Should retained distribution bars be drawn?
#' @param show_cumulative Should the cumulative percent-finer curve be drawn?
#' @param show_d_values Should selected D-values be marked when resolvable?
#' @param show_fraction_bands Should fraction boundary markers be drawn?
#' @param show_summary Should a summary caption be added?
#' @param interpolation_scale Interpolation scale passed to D-value, fraction,
#'   Folk and Ward, and index calculations.
#' @param extrapolate Extrapolation behavior passed to summary calculations.
#'   The default `"error"` avoids silent extrapolation into open-ended terminal
#'   classes. Use `"warn_linear"` explicitly when extrapolated summaries are
#'   acceptable.
#' @param moments_open_end Reserved for consistency with grain-size reporting
#'   workflows. Moment statistics are not displayed by this plot.
#'
#' @return A `ggplot` object.
#' @export
plot_gradistat_summary <- function(
    x,
    sample_id = NULL,
    x_scale = c("phi", "log10", "linear_um"),
    fraction_scheme = "gradistat",
    d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
    show_distribution = TRUE,
    show_cumulative = TRUE,
    show_d_values = TRUE,
    show_fraction_bands = TRUE,
    show_summary = TRUE,
    interpolation_scale = "phi",
    extrapolate = "error",
    moments_open_end = "error") {
  x_scale <- match.arg(x_scale)
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))
  if (!identical(moments_open_end, "error")) {
    warning("`moments_open_end` is reserved and is not used by `plot_gradistat_summary()`.", call. = FALSE)
  }

  data <- gradistat_summary_data_internal(
    x = x,
    sample_id = sample_id,
    x_scale = x_scale,
    fraction_scheme = fraction_scheme,
    d_values = d_values,
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate
  )

  p <- ggplot2::ggplot()

  if (show_distribution) {
    p <- p + ggplot2::geom_col(
      data = data$distribution,
      ggplot2::aes(x = .data$x_value, y = .data$retained_percent),
      fill = "grey75",
      color = "grey35",
      alpha = 0.75
    )
  }

  if (show_cumulative) {
    p <- p +
      ggplot2::geom_line(
        data = data$cumulative,
        ggplot2::aes(x = .data$x_value, y = .data$percent_finer),
        color = "#1f78b4",
        linewidth = 0.8
      ) +
      ggplot2::geom_point(
        data = data$cumulative,
        ggplot2::aes(x = .data$x_value, y = .data$percent_finer),
        color = "#1f78b4",
        size = 1.8
      )
  }

  if (show_fraction_bands && nrow(data$fraction_boundaries) > 0) {
    p <- p + ggplot2::geom_vline(
      data = data$fraction_boundaries,
      ggplot2::aes(xintercept = .data$x_value),
      linetype = "dotted",
      color = "grey45"
    )
  }

  if (show_d_values && !is.null(data$d_values)) {
    p <- p +
      ggplot2::geom_vline(
        data = data$d_values,
        ggplot2::aes(xintercept = .data$x_value),
        linetype = "dashed",
        color = "#b2182b",
        alpha = 0.65
      ) +
      ggplot2::geom_text(
        data = data$d_values,
        ggplot2::aes(x = .data$x_value, y = 100, label = paste0("D", .data$percentile)),
        angle = 90,
        vjust = -0.25,
        hjust = 1,
        size = 3,
        color = "#b2182b"
      )
  }

  caption <- if (show_summary && nzchar(data$summary_caption)) data$summary_caption else NULL

  p <- p +
    ggplot2::coord_cartesian(ylim = c(0, 105), clip = "off") +
    ggplot2::labs(
      title = paste("Grain-size summary:", data$sample_id),
      x = switch(
        x_scale,
        phi = "Grain size (phi; coarser to finer)",
        log10 = "Grain size (um, log10 scale)",
        linear_um = "Grain size (um)"
      ),
      y = "Percent",
      caption = caption
    ) +
    ggplot2::theme_minimal()

  if (x_scale == "log10") {
    p <- p + ggplot2::scale_x_log10()
  }

  p
}
