texture_polygon_columns <- c(
  "scheme",
  "class_id",
  "class_name",
  "vertex_id",
  "left",
  "right",
  "top",
  "left_component",
  "right_component",
  "top_component",
  "reference_id",
  "reference"
)

#' Create an empty texture polygon template
#'
#' `texture_polygon_template()` returns an empty tibble with the required
#' schema for user-supplied ternary texture polygons. The package does not
#' include built-in real texture-class polygon datasets in this phase.
#'
#' @return An empty tibble with texture polygon columns.
#' @export
texture_polygon_template <- function() {
  tibble::tibble(
    scheme = character(),
    class_id = character(),
    class_name = character(),
    vertex_id = integer(),
    left = numeric(),
    right = numeric(),
    top = numeric(),
    left_component = character(),
    right_component = character(),
    top_component = character(),
    reference_id = character(),
    reference = character()
  )
}

#' List planned texture polygon source registries
#'
#' `texture_polygon_sources()` returns metadata for texture polygon datasets
#' that may be added in future phases from original official or academic
#' sources. It does not include polygon coordinates or class vertex tables.
#'
#' @return A tibble describing planned texture polygon sources.
#' @export
texture_polygon_sources <- function() {
  audit <- texture_source_audit()
  planned <- audit[audit$texture_polygon_status != "not_planned", ]

  tibble::tibble(
    scheme = planned$scheme,
    scheme_name = planned$scheme_name,
    particle_size_system = planned$particle_size_system,
    left_component = planned$left_component,
    right_component = planned$right_component,
    top_component = planned$top_component,
    polygon_status = ifelse(planned$texture_polygon_status == "implemented", "implemented", "planned"),
    primary_source = planned$primary_source_short,
    notes = planned$implementation_note
  )
}

#' Validate user-supplied texture polygons
#'
#' `validate_texture_polygons()` checks the schema and coordinate consistency of
#' user-supplied ternary texture polygons. Polygon coordinates must be supplied
#' by users or future cited data sources; this package does not vendor polygon
#' coordinates from external R packages.
#'
#' @param polygons A data frame containing texture polygon vertices.
#'
#' @return A validated tibble with class `texture_polygons`.
#' @export
validate_texture_polygons <- function(polygons) {
  if (!is.data.frame(polygons)) {
    stop("`polygons` must be a data frame.", call. = FALSE)
  }

  missing_cols <- setdiff(texture_polygon_columns, names(polygons))
  if (length(missing_cols) > 0) {
    stop(
      "`polygons` is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  out <- tibble::as_tibble(polygons[texture_polygon_columns])
  out$scheme <- as.character(out$scheme)
  out$class_id <- as.character(out$class_id)
  out$class_name <- as.character(out$class_name)
  out$left_component <- as.character(out$left_component)
  out$right_component <- as.character(out$right_component)
  out$top_component <- as.character(out$top_component)
  out$reference_id <- as.character(out$reference_id)
  out$reference <- as.character(out$reference)

  numeric_cols <- c("vertex_id", "left", "right", "top")
  for (col in numeric_cols) {
    out[[col]] <- suppressWarnings(as.numeric(out[[col]]))
  }

  if (any(!is.finite(out$vertex_id) | !is.finite(out$left) | !is.finite(out$right) | !is.finite(out$top))) {
    stop("Texture polygon vertex IDs and ternary coordinates must be finite numeric values.", call. = FALSE)
  }

  if (any(abs(out$left + out$right + out$top - 100) > 1e-6)) {
    stop("Texture polygon ternary coordinates must sum to approximately 100.", call. = FALSE)
  }

  polygon_keys <- paste(out$scheme, out$class_id, sep = "\r")
  vertex_keys <- paste(out$scheme, out$class_id, out$vertex_id, sep = "\r")
  if (any(duplicated(vertex_keys))) {
    stop("`vertex_id` must be unique within each `scheme` and `class_id`.", call. = FALSE)
  }

  counts <- table(polygon_keys)
  if (any(counts < 3)) {
    stop("Each texture polygon must contain at least three vertices.", call. = FALSE)
  }

  for (scheme in unique(out$scheme)) {
    scheme_rows <- out[out$scheme == scheme, ]
    if (
      length(unique(scheme_rows$left_component)) != 1 ||
        length(unique(scheme_rows$right_component)) != 1 ||
        length(unique(scheme_rows$top_component)) != 1
    ) {
      stop("Texture polygon axis component mapping must be consistent within each scheme.", call. = FALSE)
    }
  }

  out <- out[order(out$scheme, out$class_id, out$vertex_id), ]
  rownames(out) <- NULL
  class(out) <- c("texture_polygons", setdiff(class(out), "texture_polygons"))
  out
}
