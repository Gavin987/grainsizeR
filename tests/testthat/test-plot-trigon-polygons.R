test_that("plot_trigon still supports point-only built-in plotting", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    plot <- plot_trigon(gsd, scheme = "gradistat"),
    "dropped"
  )
  expect_s3_class(plot, "ggplot")
})

test_that("plot_trigon rejects unsupported built-in schemes early", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    plot_trigon(gsd, scheme = "hypres"),
    "`scheme` must be one of"
  )
})

test_that("plot_trigon draws user-supplied polygon overlays", {
  plot <- plot_trigon(
    fine_texture_gsd(),
    scheme = "test_triangle",
    polygons = test_texture_polygons()
  )

  expect_s3_class(plot, "ggplot")
})

test_that("plot_trigon can classify points with user polygons", {
  plot <- plot_trigon(
    fine_texture_gsd(),
    scheme = "test_triangle",
    polygons = test_texture_polygons(),
    classify = TRUE
  )

  expect_s3_class(plot, "ggplot")
})

test_that("plot_trigon rejects invalid polygon data", {
  polygons <- test_texture_polygons()[c("scheme", "class_id")]

  expect_error(
    plot_trigon(
      fine_texture_gsd(),
      scheme = "test_triangle",
      polygons = polygons
    ),
    "missing required columns"
  )
})
