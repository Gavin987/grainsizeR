test_that("gs_moments errors by default for nonzero open-ended classes", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_moments(gsd),
    "nonzero retained percent in open-ended classes"
  )
})

test_that("gs_moments estimates open-ended midpoints in phi space", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_moments(gsd, open_end = "extend_phi"),
    "estimated by extending adjacent phi intervals"
  )

  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  expect_equal(wn1$mean_moment_phi, 2.471982, tolerance = 0.000001)
  expect_equal(wn1$mean_moment_um, 180.243303, tolerance = 0.000001)
  expect_equal(wn1$sd_moment, 1.283139, tolerance = 0.000001)
  expect_equal(wn1$skewness_moment, -0.886442, tolerance = 0.000001)
  expect_equal(wn1$kurtosis_moment, 3.758830, tolerance = 0.000001)

  expect_equal(wn2$mean_moment_phi, 2.976337, tolerance = 0.000001)
  expect_equal(wn2$mean_moment_um, 127.067120, tolerance = 0.000001)
  expect_equal(wn2$sd_moment, 1.316026, tolerance = 0.000001)
  expect_equal(wn2$skewness_moment, 0.230223, tolerance = 0.000001)
  expect_equal(wn2$kurtosis_moment, 4.237658, tolerance = 0.000001)

  expect_true(all(result$open_end_estimated))
  expect_false(any(result$open_end_omitted))
})

test_that("gs_moments calculates arithmetic micrometer moments", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_moments(
      gsd,
      method = "arithmetic_um",
      open_end = "extend_phi"
    ),
    "estimated by extending adjacent phi intervals"
  )

  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  expect_equal(wn1$mean_moment_um, 299.772521, tolerance = 0.000001)
  expect_equal(wn1$sd_moment, 463.976831, tolerance = 0.000001)
  expect_equal(wn1$skewness_moment, 4.157657, tolerance = 0.000001)
  expect_equal(wn1$kurtosis_moment, 21.698938, tolerance = 0.000001)

  expect_equal(wn2$mean_moment_um, 194.435072, tolerance = 0.000001)
  expect_equal(wn2$sd_moment, 273.645988, tolerance = 0.000001)
  expect_equal(wn2$skewness_moment, 6.521562, tolerance = 0.000001)
  expect_equal(wn2$kurtosis_moment, 57.682196, tolerance = 0.000001)

  expect_equal(unique(result$mean_moment_unit), "um")
  expect_equal(unique(result$sd_moment_unit), "um")
})

test_that("gs_moments can omit open-ended classes", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_moments(gsd, open_end = "omit"),
    "truncated distribution"
  )

  expect_true(all(result$retained_percent_used < 100))
  expect_true(all(result$open_end_omitted))
  expect_false(any(result$open_end_estimated))
})
