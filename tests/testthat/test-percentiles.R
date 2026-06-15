test_that("gs_percentile calculates default phi-scale percentiles", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  percentiles <- gs_percentile(gsd, probs = c(10, 30, 50, 60, 90))

  wn1 <- percentiles[percentiles$sample_id == "WN1", ]
  wn2 <- percentiles[percentiles$sample_id == "WN2", ]

  expect_equal(wn1$grain_size_um[wn1$percentile == 10], 67.801, tolerance = 0.001)
  expect_equal(wn1$grain_size_um[wn1$percentile == 30], 98.010, tolerance = 0.001)
  expect_equal(wn1$grain_size_um[wn1$percentile == 50], 154.664, tolerance = 0.001)
  expect_equal(wn1$grain_size_um[wn1$percentile == 60], 211.560, tolerance = 0.001)
  expect_equal(wn1$grain_size_um[wn1$percentile == 90], 494.346, tolerance = 0.001)

  expect_equal(wn2$grain_size_um[wn2$percentile == 10], 40.933, tolerance = 0.001)
  expect_equal(wn2$grain_size_um[wn2$percentile == 30], 84.089, tolerance = 0.001)
  expect_equal(wn2$grain_size_um[wn2$percentile == 50], 122.941, tolerance = 0.001)
  expect_equal(wn2$grain_size_um[wn2$percentile == 60], 158.216, tolerance = 0.001)
  expect_equal(wn2$grain_size_um[wn2$percentile == 90], 390.411, tolerance = 0.001)

  expect_true(all(percentiles$interpolation_scale == "phi"))
  expect_false(any(percentiles$extrapolated))
})

test_that("gs_percentile handles extrapolation policy", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn1 <- gsd[gsd$sample_id == "WN1", ]

  expect_error(
    gs_percentile(wn1, probs = 5, extrapolate = "error"),
    "outside the finite boundary curve range"
  )

  expect_warning(
    result <- gs_percentile(wn1, probs = 5, extrapolate = "warn_linear"),
    "linearly extrapolating"
  )

  expect_true(is.finite(result$grain_size_um))
  expect_true(result$extrapolated)
})

test_that("gs_percentile supports alternative scales and output unit ordering", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  log_result <- gs_percentile(gsd, probs = 50, scale = "log_um", output_unit = "mm")
  linear_result <- gs_percentile(gsd, probs = 50, scale = "linear_um", output_unit = "phi")

  expect_named(log_result, c(
    "sample_id",
    "percentile",
    "grain_size_mm",
    "grain_size_um",
    "grain_size_phi",
    "interpolation_scale",
    "extrapolated"
  ))
  expect_named(linear_result, c(
    "sample_id",
    "percentile",
    "grain_size_phi",
    "grain_size_um",
    "grain_size_mm",
    "interpolation_scale",
    "extrapolated"
  ))
  expect_true(all(log_result$interpolation_scale == "log_um"))
  expect_true(all(linear_result$interpolation_scale == "linear_um"))
})
