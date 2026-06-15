test_that("gs_folkward errors when default extrapolation is required", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn1 <- gsd[gsd$sample_id == "WN1", ]

  expect_error(
    gs_folkward(wn1),
    "outside the finite boundary curve range"
  )
})

test_that("gs_folkward calculates WN2 without extrapolation", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  result <- gs_folkward(wn2)

  expect_equal(result$mean_fw_phi, 2.883519, tolerance = 0.000001)
  expect_equal(result$mean_fw_um, 135.511, tolerance = 0.001)
  expect_equal(result$sorting_fw_phi, 1.210441, tolerance = 0.000001)
  expect_equal(result$skewness_fw, -0.049325, tolerance = 0.00001)
  expect_equal(result$kurtosis_fw, 1.075632, tolerance = 0.000001)
  expect_equal(result$mean_size_class, "fine sand")
  expect_equal(result$sorting_class, "poorly sorted")
  expect_equal(result$skewness_class, "near symmetrical")
  expect_equal(result$kurtosis_class, "mesokurtic")
  expect_false(result$any_extrapolated)
})

test_that("gs_folkward can extrapolate WN1 with a warning", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn1 <- gsd[gsd$sample_id == "WN1", ]

  expect_warning(
    result <- gs_folkward(wn1, extrapolate = "warn_linear"),
    "linearly extrapolating"
  )

  expect_equal(result$mean_fw_phi, 2.557156, tolerance = 0.000001)
  expect_equal(result$mean_fw_um, 169.910, tolerance = 0.001)
  expect_equal(result$sorting_fw_phi, 1.224308, tolerance = 0.000001)
  expect_equal(result$skewness_fw, -0.252542, tolerance = 0.00001)
  expect_equal(result$kurtosis_fw, 0.878954, tolerance = 0.000001)
  expect_equal(result$mean_size_class, "fine sand")
  expect_equal(result$sorting_class, "poorly sorted")
  expect_equal(result$skewness_class, "coarse skewed")
  expect_equal(result$kurtosis_class, "platykurtic")
  expect_true(result$any_extrapolated)
})
