test_that("plot_distribution returns ggplot objects", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_s3_class(plot_distribution(gsd, sample_id = "WN2"), "ggplot")
  expect_s3_class(plot_distribution(gsd, sample_id = "WN2", type = "line"), "ggplot")
  expect_s3_class(plot_distribution(gsd, sample_id = "WN2", cumulative = TRUE), "ggplot")
})

test_that("plot_cumulative returns ggplot objects", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_s3_class(plot_cumulative(gsd, sample_id = "WN2"), "ggplot")
  expect_s3_class(
    plot_cumulative(
      gsd,
      sample_id = "WN2",
      show_percentiles = c(10, 50, 90),
      extrapolate = "warn_linear"
    ),
    "ggplot"
  )
})

test_that("plot_fractions returns a ggplot object", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_s3_class(plot_fractions(gsd, scheme = "wentworth_major"), "ggplot")
  plot <- plot_fractions(gsd, scheme = "gravel_sand_mud", fill_palette = "YlOrBr")
  expect_s3_class(plot, "ggplot")
})

test_that("plot_trigon warns and drops unresolved samples", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    plot <- plot_trigon(gsd, scheme = "gradistat", normalize = "none"),
    "dropped"
  )
  expect_s3_class(plot, "ggplot")
})

test_that("plot_trigon errors when all samples are unresolved", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn1 <- gsd[gsd$sample_id == "WN1", ]

  expect_error(
    suppressWarnings(plot_trigon(wn1, scheme = "gradistat", normalize = "none")),
    "No samples have fully resolved ternary components"
  )
})
