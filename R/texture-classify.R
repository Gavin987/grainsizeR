built_in_fraction_scheme <- function(scheme, components) {
  built_in <- c("gradistat", "usda_tt", "isss", "uk_ssew", "wentworth_major")
  if (scheme %in% built_in) {
    return(scheme)
  }

  if (setequal(components, c("sand", "silt", "clay"))) {
    return("usda_tt")
  }

  stop(
    "No built-in fraction scheme is available for components: ",
    paste(components, collapse = ", "),
    call. = FALSE
  )
}

polygon_axis_components <- function(polygons, scheme, components = NULL) {
  scheme_polygons <- polygons[polygons$scheme == scheme, ]
  if (nrow(scheme_polygons) == 0) {
    stop("No texture polygons found for scheme `", scheme, "`.", call. = FALSE)
  }

  if (!is.null(components)) {
    if (is.null(names(components)) || !all(c("left", "right", "top") %in% names(components))) {
      stop("`components` must be a named character vector with left, right, and top entries.", call. = FALSE)
    }
    return(unname(components[c("left", "right", "top")]))
  }

  c(
    scheme_polygons$left_component[1],
    scheme_polygons$right_component[1],
    scheme_polygons$top_component[1]
  )
}

polygon_xy <- function(polygons) {
  coords <- ternary_to_xy(polygons$left, polygons$right, polygons$top)
  coords$scheme <- polygons$scheme
  coords$class_id <- polygons$class_id
  coords$class_name <- polygons$class_name
  coords$vertex_id <- polygons$vertex_id
  coords
}

classify_one_sample <- function(sample_row, polygons_xy, scheme, normalize, interpolation_scale) {
  if (!sample_row$resolved) {
    return(tibble::tibble(
      sample_id = sample_row$sample_id,
      scheme = scheme,
      class_id = NA_character_,
      class_name = NA_character_,
      left = sample_row$left,
      right = sample_row$right,
      top = sample_row$top,
      x = sample_row$x,
      y = sample_row$y,
      resolved = FALSE,
      ambiguous = FALSE,
      normalize = normalize,
      interpolation_scale = interpolation_scale
    ))
  }

  class_ids <- unique(polygons_xy$class_id)
  hits <- logical(length(class_ids))

  for (i in seq_along(class_ids)) {
    poly <- polygons_xy[polygons_xy$class_id == class_ids[i], ]
    hits[i] <- point_in_polygon(sample_row$x, sample_row$y, poly$x, poly$y)
  }

  matched <- class_ids[hits]
  ambiguous <- length(matched) > 1
  class_id <- if (length(matched) == 0) NA_character_ else matched[1]
  class_name <- if (is.na(class_id)) {
    NA_character_
  } else {
    polygons_xy$class_name[polygons_xy$class_id == class_id][1]
  }

  tibble::tibble(
    sample_id = sample_row$sample_id,
    scheme = scheme,
    class_id = class_id,
    class_name = class_name,
    left = sample_row$left,
    right = sample_row$right,
    top = sample_row$top,
    x = sample_row$x,
    y = sample_row$y,
    resolved = TRUE,
    ambiguous = ambiguous,
    normalize = normalize,
    interpolation_scale = interpolation_scale
  )
}

#' Classify USDA texture percentages with the internal major-class rules
#'
#' @noRd
classify_usda_texture_rules <- function(x,
                                        normalize,
                                        interpolation_scale,
                                        unresolved,
                                        extrapolate,
                                        sum_tol = 1e-6) {
  input <- usda_texture_percentages(x, normalize, interpolation_scale, unresolved, extrapolate)
  invalid <- !is.finite(input$sand) | !is.finite(input$silt) | !is.finite(input$clay) |
    input$sand < 0 | input$sand > 100 |
    input$silt < 0 | input$silt > 100 |
    input$clay < 0 | input$clay > 100
  if (any(invalid)) {
    stop("USDA texture percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
  }

  bad_sum <- abs(input$sand + input$silt + input$clay - 100) > sum_tol
  if (any(bad_sum)) {
    stop("USDA texture percentages must sum to approximately 100.", call. = FALSE)
  }

  rules <- .classify_usda_major_texture_rules(
    sand = input$sand,
    silt = input$silt,
    clay = input$clay,
    sum_tol = sum_tol
  )

  out <- input
  out$texture_class_id <- rules$class_id
  out$texture_class <- rules$class_name
  out$classification_method <- "usda_major_rules"
  out$rule_status <- rules$rule_status
  out$all_rule_matches <- rules$all_rule_matches
  out$rule_conflict <- rules$rule_conflict
  out$rule_gap <- rules$rule_gap
  tibble::as_tibble(out)
}

#' Extract USDA sand, silt, and clay percentages from supported inputs
#'
#' @noRd
usda_texture_percentages <- function(x,
                                     normalize,
                                     interpolation_scale,
                                     unresolved,
                                     extrapolate) {
  if (is_gsd_tbl(x)) {
    fractions <- gs_fractions_wide(
      x,
      scheme = "usda_tt",
      normalize = normalize,
      interpolation_scale = interpolation_scale,
      unresolved = unresolved,
      extrapolate = extrapolate
    )
    required_cols <- c("sand_percent", "silt_percent", "clay_percent")
    missing_cols <- setdiff(required_cols, names(fractions))
    if (length(missing_cols) > 0) {
      stop("Required USDA fraction columns are missing: ", paste(missing_cols, collapse = ", "), call. = FALSE)
    }
    return(tibble::tibble(
      sample_id = fractions$sample_id,
      sand = fractions$sand_percent,
      silt = fractions$silt_percent,
      clay = fractions$clay_percent
    ))
  }

  if (!is.data.frame(x)) {
    stop("`x` must be a gsd_tbl or a data frame with sand, silt, and clay percentages.", call. = FALSE)
  }

  if (all(c("sand", "silt", "clay") %in% names(x))) {
    out <- x
  } else if (all(c("left", "right", "top") %in% names(x))) {
    out <- x
    out$sand <- out$left
    out$silt <- out$right
    out$clay <- out$top
  } else {
    stop("USDA rule classification requires sand, silt, and clay columns.", call. = FALSE)
  }

  if (!is.numeric(out$sand) || !is.numeric(out$silt) || !is.numeric(out$clay)) {
    stop("USDA texture percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
  }
  tibble::as_tibble(out)
}

gradistat_texture_percentages <- function(x,
                                          basis,
                                          normalize,
                                          interpolation_scale,
                                          unresolved,
                                          extrapolate) {
  if (!is_gsd_tbl(x)) {
    return(.canonical_ternary_component_table(
      x,
      component_set = basis,
      texture_system = "gradistat"
    ))
  }

  fraction_scheme <- if (basis == "gravel_sand_mud") "gravel_sand_mud" else "gradistat"
  fractions <- gs_fractions_wide(
    x,
    scheme = fraction_scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale,
    unresolved = unresolved,
    extrapolate = extrapolate
  )

  required_cols <- if (basis == "gravel_sand_mud") {
    c("gravel_percent", "sand_percent", "mud_percent")
  } else {
    c("sand_percent", "silt_percent", "clay_percent")
  }
  missing_cols <- setdiff(required_cols, names(fractions))
  if (length(missing_cols) > 0) {
    stop("Required GRADISTAT fraction columns are missing: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  out <- tibble::tibble(sample_id = fractions$sample_id)
  if (basis == "gravel_sand_mud") {
    out$gravel <- fractions$gravel_percent
    out$sand <- fractions$sand_percent
    out$mud <- fractions$mud_percent
  } else {
    out$sand <- fractions$sand_percent
    out$silt <- fractions$silt_percent
    out$clay <- fractions$clay_percent
  }
  out
}

#' Classify samples with texture classes
#'
#' `classify_texture()` classifies samples with either the validated internal
#' USDA 12-class major texture rules or user-supplied texture polygon vertices.
#' USDA rule classification is available with `scheme = "usda_tt"` and
#' `method = "rules"` or `method = "auto"`. The USDA path uses sand, silt, and
#' clay percentages and covers only the 12 major USDA texture ternary classes.
#' GRADISTAT-style rule classification is available with `scheme = "gradistat"`
#' and `method = "rules"` or `method = "auto"`. It supports
#' `basis = "gravel_sand_mud"` for physical sediment textural groups and
#' `basis = "sand_silt_clay_no_gravel"` for no-gravel sand-silt-clay mini
#' texture classes. When `x` is a `gsd_tbl`, USDA and GRADISTAT rule paths
#' derive the needed fractions from the normalized particle-size scale stored in
#' the object; users do not need to choose size units in texture functions after
#' import. The GRADISTAT path re-expresses user-provided GRADISTAT v8 workbook
#' decision tables in R and does not copy VBA source code. Full
#' downstream sediment-name composition is supported separately and GRADISTAT
#' ternary plotting is available through `plot_texture_ternary()`.
#'
#' For rule-based paths, input percentages must be numeric, finite, between 0
#' and 100, and sum to approximately 100; the function does not silently
#' normalize invalid sums.
#' It does not implement sand-size modifier subclasses such as coarse sand,
#' fine sand, very fine sand, coarse sandy loam, fine sandy loam, or very fine
#' sandy loam. Those may be added later as qualitative descriptor columns for
#' D50 or particle-size summaries.
#'
#' Generic polygon classification remains available by supplying
#' `texture_polygons` or the legacy positional `polygons` argument. No built-in
#' USDA polygon dataset is bundled.
#'
#' @param x A valid `gsd_tbl` object, or for USDA rule classification a data
#'   frame with numeric `sand`, `silt`, and `clay` percentage columns. Data
#'   frames with ternary `left`, `right`, and `top` columns are also accepted
#'   for USDA rules and are mapped as `left = sand`, `right = silt`, and
#'   `top = clay`. For polygon classification, `x` must be a `gsd_tbl`.
#' @param polygons User-supplied texture polygon data. This legacy positional
#'   argument is equivalent to `texture_polygons`.
#' @param scheme Texture classification scheme. Use `"usda_tt"` with
#'   `method = "rules"` or `method = "auto"` for USDA major texture rules.
#'   Use `"gradistat"` with `method = "rules"` or `method = "auto"` for
#'   GRADISTAT-style rule classification. Other non-USDA schemes require
#'   user-supplied polygons because no built-in texture polygon datasets are
#'   bundled.
#' @param method Classification method. `"auto"` uses USDA rules when
#'   `scheme = "usda_tt"` or GRADISTAT rules when `scheme = "gradistat"` and no
#'   polygons are supplied, and polygon classification when polygons are
#'   supplied. `"rules"` selects a supported rule classifier. `"polygon"`
#'   selects user-supplied polygon classification.
#' @param texture_polygons User-supplied texture polygon data.
#' @param basis Rule-classification basis. For `scheme = "gradistat"`, use
#'   `"gravel_sand_mud"` with `gravel`, `sand`, and `mud` columns, or
#'   `"sand_silt_clay_no_gravel"` with `sand`, `silt`, and `clay` columns.
#'   USDA classification ignores this argument.
#' @param include_sediment_name Logical. For GRADISTAT rule classification,
#'   `TRUE` appends GRADISTAT-style sediment-name fields using
#'   `gs_gradistat_sediment_name()`. Missing subclass columns produce a partial
#'   sediment-name status instead of invented modifiers. USDA and polygon
#'   classification ignore this argument.
#' @param normalize Normalization mode passed to `gs_fractions_wide()`.
#' @param interpolation_scale Interpolation scale passed to
#'   `gs_fractions_wide()`.
#' @param unresolved Unresolved-threshold behavior passed to
#'   `gs_fractions_wide()`.
#' @param extrapolate Extrapolation behavior passed to `gs_fractions_wide()`.
#' @param components Optional named character vector mapping left, right, and
#'   top ternary axes to fraction components.
#'
#' @return A tibble with one row per sample and texture class assignment. USDA
#'   rule classification returns the input rows with `texture_class_id`,
#'   `texture_class`, `classification_method`, `rule_status`,
#'   `all_rule_matches`, `rule_conflict`, and `rule_gap` appended. For valid
#'   USDA inputs, `classification_method` is `"usda_major_rules"` and
#'   `rule_status` is `"classified"`. GRADISTAT rule classification returns the
#'   input rows with `texture_class_id`, `texture_class`,
#'   `classification_method`, `classification_status`, `ternary_basis`, `notes`,
#'   and a ratio audit column appended. If `include_sediment_name = TRUE`,
#'   GRADISTAT outputs also include `sediment_name` and related sediment-name
#'   audit columns. Polygon classification returns columns matching
#'   `texture_polygon_template()`, including `class_id`, `class_name`, `left`,
#'   `right`, `top`, `x`, `y`, `resolved`, and `ambiguous`.
#'
#' @examples
#' samples <- data.frame(
#'   sample_id = c("A", "B", "C"),
#'   sand = c(85, 40, 20),
#'   silt = c(10, 40, 20),
#'   clay = c(5, 20, 60)
#' )
#'
#' classify_texture(samples, scheme = "usda_tt", method = "rules")
#' classify_texture(samples, scheme = "usda_tt", method = "auto")
#'
#' gsm <- data.frame(
#'   sample_id = c("A", "B", "C"),
#'   gravel = c(0, 10, 40),
#'   sand = c(95, 80, 40),
#'   mud = c(5, 10, 20)
#' )
#'
#' classify_texture(
#'   gsm,
#'   scheme = "gradistat",
#'   method = "rules",
#'   basis = "gravel_sand_mud",
#'   include_sediment_name = TRUE
#' )
#'
#' ssc <- data.frame(
#'   sample_id = c("A", "B", "C"),
#'   sand = c(95, 60, 20),
#'   silt = c(3, 30, 60),
#'   clay = c(2, 10, 20)
#' )
#'
#' classify_texture(
#'   ssc,
#'   scheme = "gradistat",
#'   method = "rules",
#'   basis = "sand_silt_clay_no_gravel"
#' )
#'
#' polygons <- data.frame(
#'   scheme = "synthetic_ternary",
#'   class_id = "all",
#'   class_name = "Synthetic full ternary area",
#'   vertex_id = 1:3,
#'   left = c(100, 0, 0),
#'   right = c(0, 100, 0),
#'   top = c(0, 0, 100),
#'   left_component = "sand",
#'   right_component = "silt",
#'   top_component = "clay",
#'   reference_id = NA_character_,
#'   reference = NA_character_
#' )
#' polygons <- validate_texture_polygons(polygons)
#'
#' synthetic <- data.frame(
#'   sample_id = rep("A", 4),
#'   size_mm = c(2, 0.05, 0.002, 0.001),
#'   retained = c(10, 40, 30, 20)
#' )
#' synthetic_gs <- as_gsd_tbl(
#'   synthetic,
#'   sample_id,
#'   size_mm,
#'   retained,
#'   value_type = "percent"
#' )
#' classify_texture(
#'   synthetic_gs,
#'   texture_polygons = polygons,
#'   scheme = "synthetic_ternary",
#'   method = "polygon"
#' )
#'
#' @export
classify_texture <- function(x,
                             polygons = NULL,
                             scheme = NULL,
                             method = c("auto", "rules", "polygon"),
                             texture_polygons = NULL,
                             normalize = "none",
                             interpolation_scale = "phi",
                             unresolved = "warn_na",
                             extrapolate = "error",
                             components = NULL,
                             basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel"),
                             include_sediment_name = FALSE) {
  method <- match.arg(method)
  basis <- match.arg(basis)
  if (!is.logical(include_sediment_name) || length(include_sediment_name) != 1 || is.na(include_sediment_name)) {
    stop("`include_sediment_name` must be TRUE or FALSE.", call. = FALSE)
  }
  normalize <- match.arg(normalize, c("none", "fine_earth"))
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  unresolved <- match.arg(unresolved, c("warn_na", "error"))
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  if (!is.null(texture_polygons)) {
    if (!is.null(polygons)) {
      stop("Supply texture polygons with either `polygons` or `texture_polygons`, not both.", call. = FALSE)
    }
    polygons <- texture_polygons
  }
  has_polygons <- !is.null(polygons)
  if (is.null(scheme)) {
    stop("`scheme` must be supplied.", call. = FALSE)
  }

  if (method == "auto") {
    method <- if (has_polygons) {
      "polygon"
    } else if (identical(scheme, "usda_tt") || identical(scheme, "gradistat")) {
      "rules"
    } else {
      "polygon"
    }
  }

  if (method == "rules") {
    if (identical(scheme, "usda_tt")) {
      return(classify_usda_texture_rules(
        x = x,
        normalize = normalize,
        interpolation_scale = interpolation_scale,
        unresolved = unresolved,
        extrapolate = extrapolate
      ))
    }
    if (identical(scheme, "gradistat")) {
      gradistat_input <- gradistat_texture_percentages(
        x = x,
        basis = basis,
        normalize = normalize,
        interpolation_scale = interpolation_scale,
        unresolved = unresolved,
        extrapolate = extrapolate
      )
      result <- .classify_gradistat_texture_rules(
        x = gradistat_input,
        basis = basis
      )
      if (include_sediment_name) {
        result <- gs_gradistat_sediment_name(result, basis = basis)
      }
      return(result)
    }
    stop("Rule-based texture classification is currently available only for schemes `usda_tt` and `gradistat`.", call. = FALSE)
  }

  if (!has_polygons) {
    stop(
      "No built-in texture polygon dataset is bundled for scheme `", scheme,
      "`. Supply `texture_polygons` or use `scheme = \"usda_tt\"` or `scheme = \"gradistat\"` with `method = \"rules\"`.",
      call. = FALSE
    )
  }

  validate_gsd_tbl(x)
  polygons <- validate_texture_polygons(polygons)
  scheme_polygons <- polygons[polygons$scheme == scheme, ]
  if (nrow(scheme_polygons) == 0) {
    stop("No texture polygons found for scheme `", scheme, "`.", call. = FALSE)
  }

  axis_components <- polygon_axis_components(polygons, scheme, components)
  fraction_scheme <- built_in_fraction_scheme(scheme, axis_components)
  fractions <- gs_fractions_wide(
    x,
    scheme = fraction_scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale,
    unresolved = unresolved,
    extrapolate = extrapolate
  )

  required_cols <- paste0(axis_components, "_percent")
  missing_cols <- setdiff(required_cols, names(fractions))
  if (length(missing_cols) > 0) {
    stop("Required fraction columns are missing: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  resolved <- stats::complete.cases(fractions[required_cols])
  coords <- tibble::tibble(
    sample_id = fractions$sample_id,
    left = fractions[[required_cols[1]]],
    right = fractions[[required_cols[2]]],
    top = fractions[[required_cols[3]]],
    resolved = resolved
  )
  valid <- resolved
  if (any(valid)) {
    xy <- ternary_to_xy(coords$left[valid], coords$right[valid], coords$top[valid])
    coords$x <- NA_real_
    coords$y <- NA_real_
    coords$x[valid] <- xy$x
    coords$y[valid] <- xy$y
  } else {
    coords$x <- NA_real_
    coords$y <- NA_real_
  }

  polygons_xy <- polygon_xy(scheme_polygons)
  class_ids <- unique(polygons_xy$class_id)
  polygons_xy$class_id <- factor(polygons_xy$class_id, levels = sort(class_ids))
  polygons_xy <- polygons_xy[order(polygons_xy$class_id, polygons_xy$vertex_id), ]
  polygons_xy$class_id <- as.character(polygons_xy$class_id)

  rows <- lapply(seq_len(nrow(coords)), function(i) {
    classify_one_sample(coords[i, ], polygons_xy, scheme, normalize, interpolation_scale)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
