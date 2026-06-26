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
    usda_tt = c("sand", "silt", "clay"),
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
  finite_boundaries <- sample_x$raw_size_um[!sample_x$is_open_lower]
  sand_lower <- scheme_components(scheme)$lower_um[scheme_components(scheme)$component == "sand"][1]
  sum(finite_boundaries < sand_lower) >= 2
}

#' Plot samples on a ternary diagram
#'
#' `plot_trigon()` is a compatibility plotting name for texture ternary plots.
#' Prefer `plot_texture_ternary()` in new code and prose. Optional
#' user-supplied polygons can be drawn as overlays, but the package does not
#' include built-in texture classification polygon datasets in this phase.
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
#'
#' @return A `ggplot` object.
#' @export
plot_trigon <- function(x,
                        scheme = c("gradistat", "usda_tt", "isss", "uk_ssew"),
                        components = NULL,
                        normalize = "none",
                        sample_id = NULL,
                        labels = TRUE,
                        polygons = NULL,
                        show_polygons = TRUE,
                        show_polygon_labels = TRUE,
                        polygon_alpha = 0.15,
                        classify = FALSE) {
  validate_gsd_tbl(x)
  if (is.null(polygons)) {
    scheme <- match.arg(scheme)
  } else {
    scheme <- as.character(scheme)[1]
    polygons <- validate_texture_polygons(polygons)
  }
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

  triangle <- tibble::tibble(
    x = c(0, 1, 0.5, 0),
    y = c(0, 0, sqrt(3) / 2, 0)
  )

  p <- ggplot2::ggplot() +
    ggplot2::geom_path(data = triangle, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = NULL, y = NULL)

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
        inherit.aes = FALSE
      )
    }
  }

  if (classify && "class_name" %in% names(coords)) {
    p <- p + ggplot2::geom_point(data = coords, ggplot2::aes(x = .data$x, y = .data$y, color = .data$class_name))
  } else {
    p <- p + ggplot2::geom_point(data = coords, ggplot2::aes(x = .data$x, y = .data$y))
  }

  if (labels) {
    p <- p + ggplot2::geom_text(data = coords, ggplot2::aes(x = .data$x, y = .data$y, label = .data$sample_id), vjust = -0.8)
  }

  p
}

#' Plot samples on a texture ternary plot
#'
#' `plot_texture_triangle()` is retained as a stable compatibility function
#' name, but it creates texture ternary plots. Prefer
#' `plot_texture_ternary()` in new code and prose. Both functions use
#' grain-size fraction components and optional user-supplied texture polygons.
#' The package draws the ternary diagram with ggplot2 and does not depend on
#' external ternary plotting packages.
#'
#' For `scheme = "gradistat"` and data-frame inputs, the function can draw
#' GRADISTAT-style ternary plots for `basis = "gravel_sand_mud"` and
#' `basis = "sand_silt_clay_no_gravel"`. These plots use internal boundary
#' definitions generated from the package's re-expressed GRADISTAT decision
#' rules. They support point overlays and return ggplot objects; full visual
#' parity with the original Excel output is not claimed. The existing gsd_tbl
#' and user-supplied polygon workflows are preserved.
#'
#' @inheritParams plot_trigon
#' @param basis GRADISTAT ternary plotting basis. Supported values are
#'   `"gravel_sand_mud"` and `"sand_silt_clay_no_gravel"`.
#' @param point_id Optional column name used for point labels in GRADISTAT
#'   data-frame plots.
#' @param show_boundaries Should GRADISTAT classification boundaries be drawn?
#' @param show_classes Should GRADISTAT class labels be drawn?
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
plot_texture_triangle <- function(x,
                                  scheme = c("gradistat", "usda_tt", "isss", "uk_ssew"),
                                  components = NULL,
                                  normalize = "none",
                                  sample_id = NULL,
                                  labels = TRUE,
                                  polygons = NULL,
                                  show_polygons = TRUE,
                                  show_polygon_labels = TRUE,
                                  polygon_alpha = 0.15,
                                  classify = FALSE,
                                  basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel"),
                                  point_id = NULL,
                                  show_boundaries = TRUE,
                                  show_classes = TRUE) {
  basis <- match.arg(basis)
  scheme_value <- if (is.null(polygons)) match.arg(scheme) else as.character(scheme)[1]
  if (identical(scheme_value, "gradistat") && is.data.frame(x) && !is_gsd_tbl(x)) {
    return(plot_gradistat_texture_ternary(
      x = x,
      basis = basis,
      point_id = point_id,
      labels = labels,
      show_boundaries = show_boundaries,
      show_classes = show_classes
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
    classify = classify
  )
}

plot_gradistat_texture_ternary <- function(x,
                                           basis,
                                           point_id,
                                           labels,
                                           show_boundaries,
                                           show_classes) {
  points <- .gradistat_ternary_points(x, basis = basis, point_id = point_id)
  outline <- tibble::tibble(
    x = c(0, 1, 0.5, 0),
    y = c(0, 0, sqrt(3) / 2, 0)
  )
  axis_labels <- .gradistat_ternary_axis_labels(basis)

  p <- ggplot2::ggplot() +
    ggplot2::geom_path(data = outline, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_text(
      data = axis_labels,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      inherit.aes = FALSE
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = NULL, y = NULL)

  if (show_boundaries) {
    segments <- .gradistat_ternary_segments(basis)
    p <- p + ggplot2::geom_path(
      data = segments,
      ggplot2::aes(x = .data$x, y = .data$y, group = .data$segment_id),
      linewidth = 0.3,
      linetype = "dashed"
    )
  }

  if (show_classes) {
    class_labels <- .gradistat_ternary_labels(basis)
    p <- p + ggplot2::geom_text(
      data = class_labels,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$class_name),
      size = 2.6,
      alpha = 0.75,
      inherit.aes = FALSE
    )
  }

  if ("texture_class" %in% names(points)) {
    p <- p + ggplot2::geom_point(
      data = points,
      ggplot2::aes(x = .data$x, y = .data$y, color = .data$texture_class)
    )
  } else {
    p <- p + ggplot2::geom_point(data = points, ggplot2::aes(x = .data$x, y = .data$y))
  }

  if (labels) {
    p <- p + ggplot2::geom_text(
      data = points,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$point_label),
      vjust = -0.8,
      inherit.aes = FALSE
    )
  }

  p
}
