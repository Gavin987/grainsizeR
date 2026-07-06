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

test_that("gs_percent_finer resolves 62.5 um via nominal equivalence on a sieve-only sample", {
  # Finest measured (finite) boundary is exactly 63 um; 62.5 um would
  # otherwise fall below it (genuinely unresolved), but is a recognized
  # nominal-equivalence match for the real 63 um boundary.
  x <- data.frame(
    sample_id = "sieve_only",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
    retained = c(0, 0, 0.223, 13.0, 76.2, 9.92, 0.657)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  result <- gs_percent_finer(gsd, sizes = 62.5, size_unit = "um", extrapolate = "error")

  expect_equal(result$percent_finer, 0.657, tolerance = 1e-8)
  expect_false(result$extrapolated)
})

test_that("nominal equivalence does not override real interpolation when the threshold is already in range", {
  # 63 um is a genuine measured boundary here, but the sample also has
  # finer-resolution data beyond it (20 um, 2 um) - 62.5 um is therefore
  # already resolvable by real interpolation between 63 um and 20 um, and
  # must NOT be silently substituted with the exact 63 um value.
  x <- data.frame(
    sample_id = "augmented",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.02, 0.002, 0.001),
    retained = c(0, 0, 0.2, 10, 60, 15, 8, 5, 1.8)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  at_63 <- gs_percent_finer(gsd, sizes = 63, size_unit = "um", extrapolate = "error")
  at_62_5 <- gs_percent_finer(gsd, sizes = 62.5, size_unit = "um", extrapolate = "error")

  expect_false(at_62_5$extrapolated)
  expect_gt(abs(at_62_5$percent_finer - at_63$percent_finer), 0)
})

test_that("nominal equivalence does not apply to unrelated boundaries", {
  # 50 um is not in any equivalence group. gs_percent_finer() has no
  # pan-mass awareness of its own (that logic lives one layer up, in
  # gs_fractions()'s percent_finer_lookup() - see test-fractions.R); a
  # genuinely out-of-range, non-equivalent request must still throw here,
  # unconditionally, exactly as before this change.
  x <- data.frame(
    sample_id = "zero_pan",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
    retained = c(0, 0, 0.223, 13.0, 76.777, 10, 0)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  expect_error(
    gs_percent_finer(gsd, sizes = 50, size_unit = "um", extrapolate = "error"),
    "outside the finite boundary size range"
  )
})
