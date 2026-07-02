trigon_components <- function(scheme, components) {
  if (!is.null(components)) {
    if (!is.character(components) || length(components) != 3) {
      stop("`components` must be a character vector of length 3.", call. = FALSE)
    }
    return(components)
  }

  switch(
    scheme,
    gradistat = c("sand", "silt", "clay"),
    usda = c("sand", "silt", "clay"),
    isss = c("sand", "silt", "clay"),
    uk_ssew = c("sand", "silt", "clay")
  )
}

polygon_plot_data <- function(polygons, scheme) {
  scheme_polygons <- polygons[polygons$scheme == scheme, ]
  coords <- polygon_xy(scheme_polygons)
  coords$group <- paste(coords$scheme, coords$class_id, sep = "\r")
  coords
}

polygon_label_data <- function(poly_data) {
  keys <- unique(poly_data$group)
  rows <- lapply(keys, function(key) {
    one <- poly_data[poly_data$group == key, ]
    tibble::tibble(
      class_id = one$class_id[1],
      class_name = one$class_name[1],
      x = mean(one$x),
      y = mean(one$y)
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

fine_resolution_ok <- function(x, sample_id, scheme) {
  sample_x <- x[x$sample_id == sample_id, ]
  finite_boundaries <- .gsd_size_mm(sample_x)[!sample_x$is_open_lower]
  components <- scheme_components(scheme)
  sand_lower <- components$lower_mm[components$component == "sand"][1]
  sum(finite_boundaries < sand_lower) >= 2
}

.ternary_base_plot <- function(axis_guides) {
  outline <- tibble::tibble(
    x = c(0, 1, 0.5, 0),
    y = c(0, 0, sqrt(3) / 2, 0)
  )

  p <- ggplot2::ggplot() +
    ggplot2::geom_path(data = outline, ggplot2::aes(x = .data$x, y = .data$y), linewidth = 0.45, color = "black") +
    ggplot2::coord_equal(xlim = c(-0.16, 1.16), ylim = c(-0.18, sqrt(3) / 2 + 0.12), clip = "off") +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw() +
    .ternary_cartesian_theme()

  .add_ternary_axis_guides(p, axis_guides)
}

#' Plot samples on a ternary diagram
#'
#' `plot_trigon()` is retained for legacy compatibility with earlier
#' grainsizeR texture plotting workflows. Prefer `plot_texture_ternary()` in
#' new code. Unlike `plot_texture_ternary()`, this function can still calculate
#' ternary fractions from a raw `gsd_tbl` for legacy built-in schemes. Optional
#' user-supplied polygons can be drawn as overlays. For USDA major texture
#' classes, the function draws internal rule-derived class boundaries without
#' depending on external texture plotting packages.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scheme Fraction or user polygon scheme.
#' @param components Optional character vector of three component names in
#'   left, right, top order.
#' @param normalize Normalization mode passed to `gs_fractions_wide()`.
#' @param sample_id Optional character vector of sample identifiers to include.
#' @param labels Should sample labels be drawn?
#' @param polygons Optional user-supplied texture polygon data.
#' @param show_polygons Should supplied polygons be drawn?
#' @param show_polygon_labels Should polygon class labels be drawn?
#' @param polygon_alpha Fill alpha for polygon overlays.
#' @param classify Should sample points be classified with `classify_texture()`?
#' @param show_boundaries Should built-in rule boundaries be drawn where
#'   available?
#' @param show_classes Should built-in class labels be drawn where available?
#' @param show_class_labels Alias for `show_classes`.
#' @param sample_label_size Text size for sample labels.
#' @param class_label_size Text size for class labels.
#' @param point_size Sample point size.
#' @param point_color Constant sample point color used when `color_by` is
#'   `NULL`.
#' @param point_alpha Sample point alpha.
#' @param color_by Optional column name used to map sample point color.
#'
#' @return A `ggplot` object.
#' @export
plot_trigon <- function(x,
                        scheme = "gradistat",
                        components = NULL,
                        normalize = "none",
                        sample_id = NULL,
                        labels = TRUE,
                        polygons = NULL,
                        show_polygons = TRUE,
                        show_polygon_labels = TRUE,
                        polygon_alpha = 0.15,
                        classify = FALSE,
                        show_boundaries = TRUE,
                        show_classes = TRUE,
                        show_class_labels = show_classes,
                        sample_label_size = 3,
                        class_label_size = 4,
                        point_size = 1.8,
                        point_color = "black",
                        point_alpha = 0.8,
                        color_by = NULL) {
  validate_gsd_tbl(x)
  if (is.null(polygons)) {
    scheme <- .validate_legacy_trigon_scheme(scheme)
  } else {
    scheme <- as.character(scheme)[1]
    polygons <- validate_texture_polygons(polygons)
  }
  show_classes <- isTRUE(show_class_labels)
  normalize <- match.arg(normalize, c("none", "fine_earth"))
  plot_x <- plot_filter_samples(x, sample_id)
  components <- if (is.null(polygons)) {
    trigon_components(scheme, components)
  } else {
    polygon_axis_components(polygons, scheme, if (is.null(components)) NULL else stats::setNames(components, c("left", "right", "top")))
  }

  if (classify) {
    classified <- classify_texture(
      plot_x,
      polygons = polygons,
      scheme = scheme,
      normalize = normalize,
      extrapolate = "warn_linear",
      components = stats::setNames(components, c("left", "right", "top"))
    )
    fractions <- classified
    keep <- classified$resolved
    coords <- classified[keep, ]
  } else {
    fraction_scheme <- if (is.null(polygons)) scheme else built_in_fraction_scheme(scheme, components)
    fractions <- suppressWarnings(gs_fractions_wide(
      plot_x,
      scheme = fraction_scheme,
      normalize = normalize,
      unresolved = "warn_na",
      extrapolate = "warn_linear"
    ))

    required_cols <- paste0(components, "_percent")
    missing_cols <- setdiff(required_cols, names(fractions))
    if (length(missing_cols) > 0) {
      stop("Required ternary fraction columns are missing: ", paste(missing_cols, collapse = ", "), call. = FALSE)
    }

    keep <- stats::complete.cases(fractions[required_cols])
    if (is.null(polygons)) {
      keep <- keep & vapply(fractions$sample_id, fine_resolution_ok, logical(1), x = plot_x, scheme = scheme)
    }
    fractions <- fractions[keep, ]
    if (nrow(fractions) > 0) {
      coords <- ternary_to_xy(
        left = fractions[[required_cols[1]]],
        right = fractions[[required_cols[2]]],
        top = fractions[[required_cols[3]]],
        normalize = TRUE
      )
      coords$sample_id <- fractions$sample_id
      if (!is.null(color_by)) {
        if (!color_by %in% names(fractions)) {
          stop("`color_by` must name a column in `x`.", call. = FALSE)
        }
        coords[[color_by]] <- fractions[[color_by]]
      }
    } else {
      coords <- tibble::tibble()
    }
  }

  if (any(!keep)) {
    warning("Samples with unresolved ternary components were dropped.", call. = FALSE)
  }

  if (nrow(coords) == 0) {
    stop("No samples have fully resolved ternary components to plot.", call. = FALSE)
  }

  guides <- if (identical(scheme, "usda")) {
    .usda_ternary_axis_guides()
  } else {
    .ternary_axis_guides(
      left = tools::toTitleCase(components[1]),
      right = tools::toTitleCase(components[2]),
      top = tools::toTitleCase(components[3])
    )
  }
  p <- .ternary_base_plot(guides)

  if (is.null(polygons) && identical(scheme, "usda")) {
    if (show_boundaries) {
      p <- p + ggplot2::geom_segment(
        data = usda_ternary_boundary_segments(),
        ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend),
        inherit.aes = FALSE,
        linewidth = 0.45,
        linetype = "solid",
        color = "black"
      )
    }
    if (show_classes) {
      p <- p + ggplot2::geom_text(
        data = usda_ternary_label_data(),
        ggplot2::aes(x = .data$x, y = .data$y, label = .data$class_label),
        inherit.aes = FALSE,
        size = class_label_size,
        color = "grey20",
        check_overlap = TRUE
      )
    }
  }

  if (!is.null(polygons) && show_polygons) {
    poly_data <- polygon_plot_data(polygons, scheme)
    p <- p +
      ggplot2::geom_polygon(
        data = poly_data,
        ggplot2::aes(x = .data$x, y = .data$y, group = .data$group, fill = .data$class_name),
        alpha = polygon_alpha,
        color = "black"
      )

    if (show_polygon_labels) {
      labels_data <- polygon_label_data(poly_data)
      p <- p + ggplot2::geom_text(
        data = labels_data,
        ggplot2::aes(x = .data$x, y = .data$y, label = .data$class_name),
        inherit.aes = FALSE,
        size = class_label_size
      )
    }
  }

  if (!is.null(color_by)) {
    p <- p + ggplot2::geom_point(
      data = coords,
      ggplot2::aes(x = .data$x, y = .data$y, color = .data[[color_by]]),
      size = point_size,
      alpha = point_alpha
    )
  } else {
    p <- p + ggplot2::geom_point(
      data = coords,
      ggplot2::aes(x = .data$x, y = .data$y),
      color = point_color,
      size = point_size,
      alpha = point_alpha
    )
  }

  if (labels) {
    p <- p + ggplot2::geom_text(
      data = coords,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$sample_id),
      vjust = -0.8,
      size = sample_label_size
    )
  }

  p
}

#' Plot samples on a texture ternary plot
#'
#' `plot_texture_ternary()` is the preferred texture ternary plotting function.
#' `plot_texture_triangle()` is a compatibility alias with equivalent behavior.
#' Both functions plot summarized ternary component percentages and optional
#' user-supplied texture polygons. A fraction scheme is the rule used by
#' `gs_fractions()` to convert size-bin data into components, a ternary basis
#' is the three-component set drawn on the diagram, and a texture system is the
#' classification or diagram style selected by `scheme`.
#' The package draws the ternary diagram with ggplot2 and does not depend on
#' external ternary plotting packages.
#'
#' The intended GRADISTAT workflow is to read grain-size data, compute
#' fractions with `gs_fractions()` or `gs_fractions_wide()`, then plot those
#' summarized components. For `scheme = "gradistat"`, use
#' `basis = "gravel_sand_mud"` with `gravel`, `sand`, and `mud` components, or
#' `basis = "sand_silt_clay_no_gravel"` with `sand`, `silt`, and `clay`
#' components. Official `gs_fractions()` long output, official
#' `gs_fractions_wide()` output with `*_percent` columns, and canonical
#' summarized tables with component columns are supported. Component column
#' matching is case-insensitive, so `Sand` and `SAND` are treated as `sand`;
#' arbitrary spelling, punctuation, or suffix variants are not interpreted.
#' Raw `gsd_tbl` input is not plotted directly for GRADISTAT ternary diagrams.
#'
#' For `scheme = "usda"` and data-frame inputs, the function accepts
#' summarized `sand`, `silt`, and `clay` percentage columns and draws USDA
#' major-class boundaries. Legacy raw-`gsd_tbl` plotting for older trigon
#' schemes remains available through `plot_trigon()`.
#'
#' @inheritParams plot_trigon
#' @param scheme Texture ternary plotting system. Use `"gradistat"` for
#'   GRADISTAT ternary diagrams or `"usda"` for USDA major-class ternary
#'   diagrams. Legacy raw-`gsd_tbl` schemes such as `"isss"` and `"uk_ssew"`
#'   remain available through `plot_trigon()`.
#' @param basis GRADISTAT ternary plotting basis. Supported values are
#'   `"gravel_sand_mud"` and `"sand_silt_clay_no_gravel"`.
#' @param point_id Optional column name used for point labels in GRADISTAT
#'   data-frame plots.
#' @param show_boundaries Should GRADISTAT classification boundaries be drawn?
#' @param show_classes Should GRADISTAT class labels be drawn?
#' @param show_class_labels Alias for `show_classes`.
#' @param show_sample_labels Should sample labels be drawn? Defaults to
#'   `FALSE` for texture ternary plots.
#' @param sample_label_size Text size for sample labels.
#' @param class_label_size Text size for class labels.
#' @param label_style Label style for GRADISTAT class labels. `"inside"` and
#'   `"callout"` use the current readable label placement, and `"none"`
#'   suppresses them.
#' @param point_size Sample point size.
#' @param point_color Constant sample point color used when `color_by` is
#'   `NULL`.
#' @param point_alpha Sample point alpha.
#' @param color_by Optional column name in the summarized ternary table used to
#'   map sample point color.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examples
#' gsm <- data.frame(
#'   sample_id = c("A", "B", "C"),
#'   gravel = c(0, 10, 40),
#'   sand = c(95, 80, 40),
#'   mud = c(5, 10, 20)
#' )
#'
#' plot_texture_ternary(
#'   gsm,
#'   scheme = "gradistat",
#'   basis = "gravel_sand_mud",
#'   point_id = "sample_id"
#' )
#'
#' ssc <- data.frame(
#'   sample_id = c("A", "B", "C"),
#'   sand = c(95, 60, 20),
#'   silt = c(3, 30, 60),
#'   clay = c(2, 10, 20)
#' )
#'
#' plot_texture_ternary(
#'   ssc,
#'   scheme = "gradistat",
#'   basis = "sand_silt_clay_no_gravel",
#'   point_id = "sample_id"
#' )
plot_texture_ternary <- function(x,
                                 scheme = "gradistat",
                                 components = NULL,
                                 normalize = "none",
                                 sample_id = NULL,
                                 labels = FALSE,
                                 polygons = NULL,
                                 show_polygons = TRUE,
                                 show_polygon_labels = TRUE,
                                 polygon_alpha = 0.15,
                                 classify = FALSE,
                                 basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel"),
                                 point_id = NULL,
                                 show_boundaries = TRUE,
                                 show_classes = TRUE,
                                 show_class_labels = show_classes,
                                 show_sample_labels = labels,
                                 sample_label_size = 3,
                                 class_label_size = 3,
                                 point_size = 1.8,
                                 point_color = "black",
                                 point_alpha = 0.8,
                                 color_by = NULL,
                                 label_style = c("inside", "callout", "none")) {
  basis <- match.arg(basis)
  label_style <- match.arg(label_style)
  show_classes <- isTRUE(show_class_labels)
  scheme_value <- if (is.null(polygons)) .validate_texture_ternary_scheme(scheme) else as.character(scheme)[1]
  if (identical(scheme_value, "usda") && is.data.frame(x) && !is_gsd_tbl(x)) {
    return(plot_usda_texture_ternary(
      x = x,
      point_id = point_id,
      labels = show_sample_labels,
      show_boundaries = show_boundaries,
      show_classes = show_classes,
      show_class_labels = show_classes,
      sample_label_size = sample_label_size,
      class_label_size = class_label_size,
      point_size = point_size,
      point_color = point_color,
      point_alpha = point_alpha,
      color_by = color_by
    ))
  }
  if (identical(scheme_value, "gradistat") && is_gsd_tbl(x)) {
    stop(
      "`plot_texture_ternary()` expects summarized ternary components. ",
      "Run `gs_fractions(x, scheme = \"gravel_sand_mud\")` before plotting GRADISTAT ternary diagrams.",
      call. = FALSE
    )
  }
  if (identical(scheme_value, "gradistat") && is.data.frame(x) && !is_gsd_tbl(x)) {
    return(plot_gradistat_texture_ternary(
      x = x,
      basis = basis,
      point_id = point_id,
      labels = show_sample_labels,
      show_boundaries = show_boundaries,
      show_classes = show_classes,
      show_class_labels = show_classes,
      sample_label_size = sample_label_size,
      class_label_size = class_label_size,
      point_size = point_size,
      point_color = point_color,
      point_alpha = point_alpha,
      color_by = color_by,
      label_style = label_style
    ))
  }

  plot_trigon(
    x = x,
    scheme = scheme_value,
    components = components,
    normalize = normalize,
    sample_id = sample_id,
    labels = labels,
    polygons = polygons,
    show_polygons = show_polygons,
    show_polygon_labels = show_polygon_labels,
    polygon_alpha = polygon_alpha,
    classify = classify,
    show_boundaries = show_boundaries,
    show_classes = show_classes,
    show_class_labels = show_classes,
    sample_label_size = sample_label_size,
    class_label_size = class_label_size,
    point_size = point_size,
    point_color = point_color,
    point_alpha = point_alpha,
    color_by = color_by
  )
}

plot_gradistat_texture_ternary <- function(x,
                                           basis,
                                           point_id,
                                           labels,
                                           show_boundaries,
                                           show_classes,
                                           show_class_labels,
                                           sample_label_size,
                                           class_label_size,
                                           point_size,
                                           point_color,
                                           point_alpha,
                                           color_by,
                                           label_style) {
  show_classes <- isTRUE(show_class_labels)
  points <- .gradistat_ternary_points(x, basis = basis, point_id = point_id, color_by = color_by)
  axis_guides <- .gradistat_ternary_axis_guides(basis)
  p <- .ternary_base_plot(axis_guides)

  if (show_boundaries) {
    segments <- .gradistat_ternary_segments(basis)
    p <- p + ggplot2::geom_path(
      data = segments,
      ggplot2::aes(x = .data$x, y = .data$y, group = .data$segment_id),
      linewidth = 0.45,
      linetype = "solid",
      color = "black"
    )
  }

  if (show_classes && label_style != "none") {
    class_labels <- .gradistat_ternary_labels(basis)
    class_labels <- class_labels[class_labels$show_label, ]
    class_labels$label_size <- class_label_size * class_labels$label_scale
    p <- p + ggplot2::geom_text(
      data = class_labels,
      ggplot2::aes(
        x = .data$x,
        y = .data$y,
        label = .data$class_label,
        size = .data$label_size
      ),
      alpha = 0.85,
      inherit.aes = FALSE,
      lineheight = 0.85,
      check_overlap = TRUE
    ) +
      ggplot2::scale_size_identity()
  }

  if (!is.null(color_by)) {
    p <- p + ggplot2::geom_point(
      data = points,
      ggplot2::aes(x = .data$x, y = .data$y, color = .data[[color_by]]),
      size = point_size,
      alpha = point_alpha
    )
  } else {
    p <- p + ggplot2::geom_point(
      data = points,
      ggplot2::aes(x = .data$x, y = .data$y),
      color = point_color,
      size = point_size,
      alpha = point_alpha
    )
  }

  if (labels) {
    p <- p + ggplot2::geom_text(
      data = points,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$point_label),
      vjust = -0.8,
      size = sample_label_size,
      inherit.aes = FALSE
    )
  }

  p
}

plot_usda_texture_ternary <- function(x,
                                      point_id,
                                      labels,
                                      show_boundaries,
                                      show_classes,
                                      show_class_labels,
                                      sample_label_size,
                                      class_label_size,
                                      point_size,
                                      point_color,
                                      point_alpha,
                                      color_by) {
  show_classes <- isTRUE(show_class_labels)
  x <- .canonical_ternary_component_table(x, component_set = "sand_silt_clay", point_id = point_id, texture_system = "usda")
  if (!is.null(color_by) && !color_by %in% names(x)) {
    stop("`color_by` must name a column in `x`.", call. = FALSE)
  }

  classified <- .classify_usda_major_texture_rules(x$sand, x$silt, x$clay)
  invalid <- classified$rule_status != "classified"
  if (any(invalid)) {
    stop("USDA ternary percentages must be finite, between 0 and 100, and sum to approximately 100.", call. = FALSE)
  }

  coords <- ternary_to_xy(left = x$sand, right = x$silt, top = x$clay, normalize = TRUE)
  coords$sample_id <- if (is.null(point_id)) {
    as.character(seq_len(nrow(x)))
  } else {
    as.character(x[[point_id]])
  }
  coords$class_name <- classified$class_name
  if (!is.null(color_by)) {
    coords[[color_by]] <- x[[color_by]]
  }

  axis_guides <- .usda_ternary_axis_guides()
  p <- .ternary_base_plot(axis_guides)

  if (show_boundaries) {
    p <- p + ggplot2::geom_segment(
      data = usda_ternary_boundary_segments(),
      ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend),
      inherit.aes = FALSE,
      linewidth = 0.45,
      linetype = "solid",
      color = "black"
    )
  }
  if (show_classes) {
    p <- p + ggplot2::geom_text(
      data = usda_ternary_label_data(),
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$class_label),
      inherit.aes = FALSE,
      size = class_label_size,
      color = "grey20",
      check_overlap = TRUE
    )
  }

  if (!is.null(color_by)) {
    p <- p + ggplot2::geom_point(
      data = coords,
      ggplot2::aes(x = .data$x, y = .data$y, color = .data[[color_by]]),
      alpha = point_alpha,
      size = point_size
    )
  } else {
    p <- p + ggplot2::geom_point(
      data = coords,
      ggplot2::aes(x = .data$x, y = .data$y),
      color = point_color,
      alpha = point_alpha,
      size = point_size
    )
  }
  if (labels) {
    p <- p + ggplot2::geom_text(
      data = coords,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$sample_id),
      vjust = -0.8,
      size = sample_label_size,
      inherit.aes = FALSE
    )
  }

  p
}
