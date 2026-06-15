test_that("gs_percent_finer returns exact finite boundary values", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_percent_finer(gsd, sizes = 62.5)
  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  wn2_terminal <- gs_percent_finer(gsd[gsd$sample_id == "WN2", ], sizes = 13.330233)

  expect_equal(wn1$percent_finer, 5.5811877, tolerance = 1e-7)
  expect_equal(wn2$percent_finer, 14.3772842, tolerance = 1e-7)
  expect_equal(wn2_terminal$percent_finer, 2.9952675, tolerance = 1e-7)
  expect_false(any(result$extrapolated))
})

test_that("gs_percent_finer accepts millimeter thresholds", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_percent_finer(gsd, sizes = 0.0625, size_unit = "mm")

  expect_equal(result$threshold_um, c(62.5, 62.5))
  expect_equal(result$percent_finer[result$sample_id == "WN1"], 5.5811877, tolerance = 1e-7)
})

test_that("gs_percent_finer handles out-of-range thresholds", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_percent_finer(gsd, sizes = 10, extrapolate = "error"),
    "outside the finite boundary size range"
  )

  expect_warning(
    result <- gs_percent_finer(
      gsd[gsd$sample_id == "WN1", ],
      sizes = 10,
      extrapolate = "warn_linear"
    ),
    "linearly extrapolating"
  )

  expect_true(all(result$extrapolated))
  expect_true(all(is.finite(result$percent_finer)))
})
