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

test_that("gs_percentile resolves ties from consecutive zero-retained classes deterministically", {
  # Reproduces the class of issue found in Q3/Q4 of G2Sd::granulo: several
  # consecutive coarse classes with zero retained mass produce an exact tie
  # in cum_finer_percent (100 at both 1000 um and 800 um here, since nothing
  # is retained between them). A percentile falling between that tied
  # plateau and the next distinct value must bracket against the *finest*
  # member of the tied plateau (800 um, nearest the real transition), not
  # an arbitrary/incidental member - see linear_interpolate()'s
  # `tie_break_um` argument.
  tie_input <- data.frame(
    sample_id = "TIE1",
    size_um = c(1000, 800, 600, 400, 200, 0),
    retained_percent = c(0, 0, 20, 30, 50, 0)
  )
  gsd_tie <- as_gsd_tbl(tie_input, sample_id, size_um, retained_percent, size_unit = "um", value_type = "percent")

  d90 <- gs_percentile(gsd_tie, probs = 90, extrapolate = "error")

  # Bracketing (600 um, 80%) with (800 um, 100%) - the finest member of the
  # tied {1000, 800} plateau - not (1000 um, 100%).
  expect_equal(d90$grain_size_um, 692.8203230276, tolerance = 1e-6)
  expect_false(d90$extrapolated)

  # A target that instead falls between the tied plateau and an even
  # smaller-percentile value close to it (99, still strictly inside (80,
  # 100)) uses the same (600, 800) bracket as d90 above, on the same ratio
  # formula - not a "snap to the plateau" shortcut.
  d99 <- gs_percentile(gsd_tie, probs = 99, extrapolate = "error")
  expect_equal(d99$grain_size_um, 788.5750826855, tolerance = 1e-6)

  # A target exactly at the plateau's own value (100, the maximum observed
  # percent_finer) is an exact match, not an interpolation, and resolves to
  # the coarsest observed boundary (1000 um) rather than either specific
  # tied-plateau member.
  d100 <- gs_percentile(gsd_tie, probs = 100, extrapolate = "error")
  expect_equal(d100$grain_size_um, 1000, tolerance = 1e-6)
})

test_that("gs_percentile is unaffected by tie-breaking changes when there are no ties", {
  # Regression guard: a curve with strictly distinct cum_finer_percent
  # values at every boundary must give byte-for-byte the same result as
  # before the tie_break_um argument was introduced (order(x, tie_break_um)
  # is identical to order(x) whenever x has no duplicates).
  notie_input <- data.frame(
    sample_id = "NOTIE1",
    size_um = c(1000, 800, 600, 400, 200, 0),
    retained_percent = c(5, 10, 20, 30, 25, 10)
  )
  gsd_notie <- as_gsd_tbl(notie_input, sample_id, size_um, retained_percent, size_unit = "um", value_type = "percent")

  d50 <- gs_percentile(gsd_notie, probs = 50, extrapolate = "error")
  expect_equal(d50$grain_size_um, 489.8979485566, tolerance = 1e-6)
})

test_that("gs_percentile matches G2Sd's D95 for a real zero-retained-mass sample (Q3 regression)", {
  # Regression test for the exact scenario found in G2Sd::granulo sample Q3
  # during JSR manuscript validation: several consecutive coarse sieve
  # classes retain nothing, producing a tie that previously made D95
  # diverge from G2Sd::granstat()'s D95 (grainsizeR gave 6053.93 um vs.
  # G2Sd's 10517.56 um). 10517.56 um is G2Sd::granstat()'s independently
  # computed reference value for this exact input, not a value derived from
  # grainsizeR itself.
  q3_input <- data.frame(
    sample_id = "Q3",
    size_um = c(
      25000, 20000, 16000, 12500, 10000, 8000, 6300, 5000, 4000,
      2500, 2000, 1600, 1250, 1000, 800, 630, 500, 400, 315,
      250, 200, 160, 125, 100, 80, 63, 50, 40, 0
    ),
    retained_percent = c(
      0, 0, 0, 0, 2.2, 0, 0, 0, 0,
      0.3, 0.1, 0.4, 1.0, 1.3, 1.6, 1.7, 2.45, 2.1, 2.3,
      2.7, 2.6, 2.7, 2.4, 2.1, 2.1, 1.3, 0.7, 0.1, 1.9
    )
  )
  gsd_q3 <- as_gsd_tbl(q3_input, sample_id, size_um, retained_percent, size_unit = "um", value_type = "weight")

  d95 <- gs_percentile(gsd_q3, probs = 95, extrapolate = "error")
  expect_equal(d95$grain_size_um, 10517.56, tolerance = 1e-2)
  expect_false(d95$extrapolated)
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
