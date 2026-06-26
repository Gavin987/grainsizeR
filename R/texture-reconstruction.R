texture_polygon_reconstruction_columns <- c(
  "scheme",
  "scheme_name",
  "class_id",
  "class_name",
  "class_name_standardized",
  "class_abbreviation",
  "vertex_id",
  "left",
  "right",
  "top",
  "left_component",
  "right_component",
  "top_component",
  "coordinate_unit",
  "axis_sum",
  "source_id",
  "primary_source_short",
  "primary_source_full",
  "source_page",
  "source_figure",
  "source_table",
  "source_url",
  "source_access_date",
  "reconstruction_method",
  "digitization_tool",
  "digitization_resolution",
  "coordinate_precision",
  "boundary_rule",
  "boundary_inclusion",
  "reconstructed_by",
  "reconstructed_date",
  "reviewed_by",
  "reviewed_date",
  "validation_status",
  "comparison_status",
  "implementation_status",
  "notes"
)

#' Create an empty texture polygon reconstruction template
#'
#' `texture_polygon_reconstruction_template()` returns an empty tibble with the
#' detailed developer-oriented schema used for future official texture polygon
#' reconstruction work. It is more detailed than [texture_polygon_template()]
#' because it records source, review, reconstruction, validation, and comparison
#' metadata.
#'
#' The returned object is a template only. It is not package polygon data and
#' contains no real polygon coordinates.
#'
#' @return An empty tibble with reconstruction-template columns.
#' @export
texture_polygon_reconstruction_template <- function() {
  tibble::tibble(
    scheme = character(),
    scheme_name = character(),
    class_id = character(),
    class_name = character(),
    class_name_standardized = character(),
    class_abbreviation = character(),
    vertex_id = integer(),
    left = numeric(),
    right = numeric(),
    top = numeric(),
    left_component = character(),
    right_component = character(),
    top_component = character(),
    coordinate_unit = character(),
    axis_sum = numeric(),
    source_id = character(),
    primary_source_short = character(),
    primary_source_full = character(),
    source_page = character(),
    source_figure = character(),
    source_table = character(),
    source_url = character(),
    source_access_date = character(),
    reconstruction_method = character(),
    digitization_tool = character(),
    digitization_resolution = character(),
    coordinate_precision = character(),
    boundary_rule = character(),
    boundary_inclusion = character(),
    reconstructed_by = character(),
    reconstructed_date = character(),
    reviewed_by = character(),
    reviewed_date = character(),
    validation_status = character(),
    comparison_status = character(),
    implementation_status = character(),
    notes = character()
  )
}

non_empty_text <- function(x) {
  !is.na(x) & nzchar(trimws(as.character(x)))
}

#' Convert a reconstruction table to texture polygons
#'
#' `reconstruction_to_texture_polygons()` converts a completed texture polygon
#' reconstruction table into the compact schema used by
#' [validate_texture_polygons()]. This helper is intended for future official
#' polygon reconstruction workflows and does not provide built-in polygon data.
#'
#' @param x A data frame with columns from
#'   [texture_polygon_reconstruction_template()].
#' @param validate Should the compact polygon table be validated with
#'   [validate_texture_polygons()] before returning?
#' @param require_ready Should rows be required to have `implementation_status`
#'   equal to `"ready_for_package"` or `"implemented"`?
#'
#' @return A tibble with compact texture polygon columns. If `validate = TRUE`,
#'   the result also has class `texture_polygons`.
#' @export
reconstruction_to_texture_polygons <- function(x, validate = TRUE, require_ready = FALSE) {
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame.", call. = FALSE)
  }

  missing_cols <- setdiff(texture_polygon_reconstruction_columns, names(x))
  if (length(missing_cols) > 0) {
    stop(
      "`x` is missing required reconstruction columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  x <- tibble::as_tibble(x[texture_polygon_reconstruction_columns])

  if (nrow(x) == 0) {
    out <- texture_polygon_template()
    if (validate) {
      out <- validate_texture_polygons(out)
    }
    return(out)
  }

  if (require_ready) {
    ready <- c("ready_for_package", "implemented")
    status <- as.character(x$implementation_status)
    if (any(is.na(status) | !(status %in% ready))) {
      stop(
        "`implementation_status` must be `ready_for_package` or `implemented` when `require_ready = TRUE`.",
        call. = FALSE
      )
    }
  }

  class_name <- ifelse(
    non_empty_text(x$class_name_standardized),
    as.character(x$class_name_standardized),
    as.character(x$class_name)
  )
  reference <- ifelse(
    non_empty_text(x$primary_source_full),
    as.character(x$primary_source_full),
    as.character(x$primary_source_short)
  )

  out <- tibble::tibble(
    scheme = as.character(x$scheme),
    class_id = as.character(x$class_id),
    class_name = class_name,
    vertex_id = suppressWarnings(as.numeric(x$vertex_id)),
    left = suppressWarnings(as.numeric(x$left)),
    right = suppressWarnings(as.numeric(x$right)),
    top = suppressWarnings(as.numeric(x$top)),
    left_component = as.character(x$left_component),
    right_component = as.character(x$right_component),
    top_component = as.character(x$top_component),
    reference_id = as.character(x$source_id),
    reference = reference
  )

  out <- out[order(out$scheme, out$class_id, out$vertex_id), ]
  rownames(out) <- NULL

  if (validate) {
    out <- validate_texture_polygons(out)
  }

  out
}
