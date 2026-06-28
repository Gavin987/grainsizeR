.gradistat_ternary_components <- function(basis) {
  basis <- match.arg(basis, c("gravel_sand_mud", "sand_silt_clay_no_gravel"))
  if (basis == "gravel_sand_mud") {
    c(left = "mud", right = "sand", top = "gravel")
  } else {
    c(left = "sand", right = "silt", top = "clay")
  }
}

.gradistat_ternary_axis_labels <- function(basis) {
  components <- .gradistat_ternary_components(basis)
  data.frame(
    label = unname(components),
    x = c(-0.03, 1.03, 0.5),
    y = c(-0.04, -0.04, sqrt(3) / 2 + 0.04),
    stringsAsFactors = FALSE
  )
}

.gradistat_line_constant_component <- function(component, threshold, basis) {
  components <- .gradistat_ternary_components(basis)
  other <- setdiff(unname(components), component)
  endpoint <- 100 - threshold
  one <- data.frame(
    left = c(0, 0),
    right = c(0, 0),
    top = c(0, 0)
  )
  names(one) <- unname(components)
  one[[component]] <- threshold
  one[[other[1]]] <- c(endpoint, 0)
  one[[other[2]]] <- c(0, endpoint)
  xy <- ternary_to_xy(one[[components["left"]]], one[[components["right"]]], one[[components["top"]]])
  data.frame(
    x = xy$x,
    y = xy$y,
    boundary = paste0(component, " = ", threshold),
    stringsAsFactors = FALSE
  )
}

.gradistat_line_ratio <- function(numerator, denominator, ratio, basis, min_third = 0, max_third = NULL) {
  components <- .gradistat_ternary_components(basis)
  third <- setdiff(unname(components), c(numerator, denominator))
  if (is.null(max_third)) {
    max_third <- if (basis == "gravel_sand_mud") 80 else 100
  }
  third_values <- c(min_third, max_third)
  one <- data.frame(
    left = c(0, 0),
    right = c(0, 0),
    top = c(0, 0)
  )
  names(one) <- unname(components)
  remaining <- 100 - third_values
  one[[third]] <- third_values
  one[[denominator]] <- remaining / (ratio + 1)
  one[[numerator]] <- ratio * one[[denominator]]
  xy <- ternary_to_xy(one[[components["left"]]], one[[components["right"]]], one[[components["top"]]])
  data.frame(
    x = xy$x,
    y = xy$y,
    boundary = paste0(numerator, " / ", denominator, " = ", ratio),
    stringsAsFactors = FALSE
  )
}

.gradistat_trace_visual_gravel <- function() {
  5
}

.gradistat_visual_gravel_boundary <- function(threshold) {
  # The gravel = 5 class boundary is drawn at the 10% visual height so the
  # schematic slightly gravelly band has readable space above the Trace guide.
  # This affects only the ternary plot framework, not classification rules.
  if (identical(threshold, 5)) {
    return(10)
  }
  threshold
}

.gradistat_ternary_segments <- function(basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel")) {
  basis <- match.arg(basis)
  if (basis == "gravel_sand_mud") {
    trace_line <- .gradistat_line_constant_component(
      component = "gravel",
      threshold = .gradistat_trace_visual_gravel(),
      basis = basis
    )
    trace_line$boundary <- "Trace"
    # The Trace line is a plotting-only guide. Local workbook-derived rule
    # notes use gravel = 0 for no-gravel classes and gravel = 5 as the true
    # upper boundary of slightly gravelly classes; no separate numeric trace
    # threshold is used for classification.
    gravel_boundaries <- lapply(c(5, 30, 80), function(threshold) {
      line <- .gradistat_line_constant_component(
        component = "gravel",
        threshold = .gradistat_visual_gravel_boundary(threshold),
        basis = basis
      )
      line$boundary <- paste0("gravel = ", threshold)
      line
    })
    rows <- c(
      list(trace_line),
      gravel_boundaries,
      list(
        .gradistat_line_ratio(numerator = "sand", denominator = "mud", ratio = 1 / 9, basis = basis, max_third = 10),
        .gradistat_line_ratio(numerator = "sand", denominator = "mud", ratio = 1, basis = basis, max_third = 80),
        .gradistat_line_ratio(numerator = "sand", denominator = "mud", ratio = 9, basis = basis, max_third = 80)
      )
    )
  } else {
    rows <- c(
      lapply(c(90, 50, 10), .gradistat_line_constant_component, component = "sand", basis = basis),
      lapply(c(2, 0.5), .gradistat_line_ratio, numerator = "silt", denominator = "clay", basis = basis)
    )
  }
  out <- do.call(rbind, rows)
  out$segment_id <- rep(seq_along(rows), each = 2)
  tibble::as_tibble(out)
}

.gradistat_ternary_labels <- function(basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel")) {
  basis <- match.arg(basis)
  if (basis == "gravel_sand_mud") {
    points <- data.frame(
      class_id = c(
        "gravel", "sandy_gravel", "gravelly_sand", "slightly_gravelly_sand",
        "sand", "muddy_sandy_gravel", "gravelly_muddy_sand",
        "slightly_gravelly_muddy_sand", "muddy_sand", "muddy_gravel",
        "gravelly_mud", "slightly_gravelly_sandy_mud", "sandy_mud",
        "slightly_gravelly_mud", "mud"
      ),
      gravel = c(82, 32, 14, 8, 2, 34, 14, 8, 3, 40, 14, 8, 3, 8, 3),
      sand = c(5, 58, 82, 88, 96, 45, 58, 65, 62, 20, 18, 28, 26, 4, 5),
      mud = c(5, 3, 4, 4, 2, 20, 25, 25, 25, 58, 65, 65, 72, 90, 94),
      show_label = c(
        TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
        TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
      )
    )
    xy <- ternary_to_xy(points$mud, points$sand, points$gravel)
  } else {
    points <- data.frame(
      class_id = c(
        "sand", "silty_sand", "muddy_sand", "clayey_sand", "sandy_silt",
        "sandy_mud", "sandy_clay", "silt", "mud", "clay"
      ),
      sand = c(95, 60, 60, 60, 20, 20, 20, 5, 5, 5),
      silt = c(3, 30, 25, 10, 60, 45, 20, 70, 55, 20),
      clay = c(2, 10, 15, 30, 20, 35, 60, 25, 40, 75)
    )
    xy <- ternary_to_xy(points$sand, points$silt, points$clay)
    points$show_label <- TRUE
  }
  data.frame(
    class_id = points$class_id,
    class_name = unname(.gradistat_class_names[points$class_id]),
    class_label = .gradistat_class_label_text(points$class_id),
    x = xy$x,
    y = xy$y,
    label_scale = ifelse(grepl("^slightly_gravelly", points$class_id), 0.65, 1),
    show_label = points$show_label,
    stringsAsFactors = FALSE
  )
}

.gradistat_class_label_text <- function(class_id) {
  names <- unname(.gradistat_class_names[class_id])
  
  labels <- gsub(" ", "\n", names, fixed = TRUE)
  
  one_line <- grepl("^slightly_", class_id) |
    class_id %in% c(
      "muddy_sand",
      "sandy_mud",
      "gravelly_muddy_sand",
      "muddy_sandy_gravel",
      "muddy_gravel",
      "gravelly_mud"
    )
  
  labels[one_line] <- names[one_line]
  
  label_overrides <- c(
    slightly_gravelly_sand = "slightly\ngravelly sand",
    slightly_gravelly_mud  = "slightly\ngravelly mud"
  )
  
  override <- class_id %in% names(label_overrides)
  labels[override] <- unname(label_overrides[class_id[override]])
  
  labels
}

.gradistat_ternary_points <- function(x, basis, point_id = NULL) {
  components <- .gradistat_ternary_components(basis)
  missing_cols <- setdiff(unname(components), names(x))
  if (length(missing_cols) > 0) {
    stop(
      "GRADISTAT `", basis, "` ternary plotting requires columns: ",
      paste(unname(components), collapse = ", "),
      call. = FALSE
    )
  }
  for (column in unname(components)) {
    if (!is.numeric(x[[column]])) {
      stop("GRADISTAT ternary plot percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
    }
  }
  invalid <- Reduce(`|`, lapply(x[unname(components)], function(value) {
    !is.finite(value) | value < 0 | value > 100
  }))
  if (any(invalid)) {
    stop("GRADISTAT ternary plot percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
  }
  sums <- rowSums(as.data.frame(x[unname(components)]))
  if (any(abs(sums - 100) > 1e-6)) {
    stop("GRADISTAT ternary plot percentages must sum to approximately 100 for the selected basis.", call. = FALSE)
  }
  if (!is.null(point_id) && !point_id %in% names(x)) {
    stop("`point_id` must name a column in `x`.", call. = FALSE)
  }
  xy <- ternary_to_xy(x[[components["left"]]], x[[components["right"]]], x[[components["top"]]])
  out <- data.frame(
    x = xy$x,
    y = xy$y,
    stringsAsFactors = FALSE
  )
  out$point_label <- if (is.null(point_id)) seq_len(nrow(x)) else as.character(x[[point_id]])
  if ("texture_class" %in% names(x)) {
    out$texture_class <- x$texture_class
  }
  tibble::as_tibble(out)
}
