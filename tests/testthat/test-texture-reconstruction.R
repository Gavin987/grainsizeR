synthetic_reconstruction <- function(status = "reconstruction_in_progress") {
  x <- texture_polygon_reconstruction_template()
  rows <- data.frame(
    scheme = "synthetic_ternary",
    scheme_name = "Synthetic triangle",
    class_id = "all",
    class_name = "Raw full triangle",
    class_name_standardized = "Synthetic full ternary area",
    class_abbreviation = "SFT",
    vertex_id = c(3, 1, 2),
    left = c(0, 100, 0),
    right = c(0, 0, 100),
    top = c(100, 0, 0),
    left_component = "sand",
    right_component = "silt",
    top_component = "clay",
    coordinate_unit = "percent",
    axis_sum = c(100, 100, 100),
    source_id = "synthetic_source",
    primary_source_short = "Synthetic short source",
    primary_source_full = "Synthetic full source for tests",
    source_page = NA_character_,
    source_figure = NA_character_,
    source_table = NA_character_,
    source_url = NA_character_,
    source_access_date = NA_character_,
    reconstruction_method = "synthetic",
    digitization_tool = NA_character_,
    digitization_resolution = NA_character_,
    coordinate_precision = "exact",
    boundary_rule = "boundary_included",
    boundary_inclusion = "Synthetic full ternary area contains all points.",
    reconstructed_by = "test",
    reconstructed_date = "2026-06-17",
    reviewed_by = NA_character_,
    reviewed_date = NA_character_,
    validation_status = "draft",
    comparison_status = "not_compared",
    implementation_status = status,
    notes = "Synthetic test data only.",
    stringsAsFactors = FALSE
  )
  rbind(x, rows)
}

test_that("texture_polygon_reconstruction_template returns empty detailed schema", {
  template <- texture_polygon_reconstruction_template()

  expect_s3_class(template, "tbl_df")
  expect_equal(nrow(template), 0)
  expect_true(all(c("left", "right", "top") %in% names(template)))
  expect_true(all(c("source_id", "implementation_status", "validation_status") %in% names(template)))
  expect_false(any(c("usda", "hypres", "isss", "uk_ssew") %in% template$scheme))
})

test_that("empty reconstruction table converts to empty compact polygon table", {
  out <- reconstruction_to_texture_polygons(texture_polygon_reconstruction_template())

  expect_s3_class(out, "texture_polygons")
  expect_equal(nrow(out), 0)
  expect_named(out, names(texture_polygon_template()))
})

test_that("synthetic reconstruction converts to validated compact polygons", {
  out <- reconstruction_to_texture_polygons(synthetic_reconstruction())

  expect_s3_class(out, "texture_polygons")
  expect_equal(nrow(out), 3)
  expect_equal(out$vertex_id, c(1, 2, 3))
  expect_equal(unique(out$class_name), "Synthetic full ternary area")
  expect_equal(unique(out$reference_id), "synthetic_source")
  expect_equal(unique(out$reference), "Synthetic full source for tests")
  expect_s3_class(validate_texture_polygons(out), "texture_polygons")
})

test_that("short source reference is used when full source is missing", {
  x <- synthetic_reconstruction()
  x$primary_source_full <- ""

  out <- reconstruction_to_texture_polygons(x)

  expect_equal(unique(out$reference), "Synthetic short source")
})

test_that("require_ready enforces implementation status", {
  expect_error(
    reconstruction_to_texture_polygons(synthetic_reconstruction(), require_ready = TRUE),
    "implementation_status"
  )

  out <- reconstruction_to_texture_polygons(
    synthetic_reconstruction(status = "ready_for_package"),
    require_ready = TRUE
  )
  expect_s3_class(out, "texture_polygons")
})

test_that("invalid reconstruction inputs error informatively", {
  x <- synthetic_reconstruction()
  x$top[1] <- 95

  expect_error(
    reconstruction_to_texture_polygons(x, validate = TRUE),
    "sum to approximately 100"
  )

  missing <- synthetic_reconstruction()
  missing$source_id <- NULL
  expect_error(
    reconstruction_to_texture_polygons(missing),
    "missing required reconstruction columns"
  )
})

test_that("converted synthetic polygons classify and plot", {
  polygons <- reconstruction_to_texture_polygons(synthetic_reconstruction())

  classified <- classify_texture(
    fine_texture_gsd(),
    polygons = polygons,
    scheme = "synthetic_ternary"
  )
  expect_true(all(classified$resolved))
  expect_equal(unique(classified$texture_class), "Synthetic full ternary area")

  p <- plot_texture_triangle(
    fine_texture_gsd(),
    scheme = "synthetic_ternary",
    polygons = polygons,
    labels = FALSE
  )
  expect_s3_class(p, "ggplot")
})
