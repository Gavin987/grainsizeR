test_that("gs_parameters returns requested D-values in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(gsd, parameters = c("D10", "D30", "D50"))

  expect_named(result, c("sample_id", "D10_um", "D30_um", "D50_um"))
  expect_equal(nrow(result), 2)
  expect_true(all(c("WN1", "WN2") %in% result$sample_id))
})

test_that("gs_parameters combines D-values and grain-size indices", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(gsd, parameters = c("D10", "D30", "indices"))

  expect_true(all(c("D10_um", "D30_um", "Cu", "Cc", "fine_content_percent") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters keeps engineering as a compatibility alias", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  preferred <- gs_parameters(gsd, parameters = c("D10", "indices"))
  compatible <- gs_parameters(gsd, parameters = c("D10", "engineering"))

  expect_equal(preferred, compatible)
})

test_that("gs_parameters supports long output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(
    gsd,
    parameters = c("D10", "D30", "indices"),
    output = "long"
  )

  expect_named(result, c("sample_id", "parameter", "value", "unit", "method"))
  expect_true(all(c("D10_um", "D30_um", "Cu", "fine_content_percent") %in% result$parameter))
})

test_that("gs_parameters rejects unknown parameters", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_parameters(gsd, parameters = c("D10", "not_a_parameter")),
    "Unsupported parameters"
  )
})

test_that("gs_parameters includes Folk and Ward columns in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  result <- gs_parameters(wn2, parameters = "folk_ward")

  expect_true(all(c("mean_fw_phi", "sorting_fw_phi", "skewness_fw", "kurtosis_fw") %in% names(result)))
  expect_true(all(c("mean_size_class", "sorting_class", "skewness_class", "kurtosis_class") %in% names(result)))
})

test_that("gs_parameters combines D-values, indices, and Folk and Ward statistics", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = c("D10", "D50", "indices", "folk_ward"),
      extrapolate = "warn_linear"
    ),
    "linearly extrapolating"
  )

  expect_true(all(c("D10_um", "D50_um", "Cu", "mean_fw_phi", "kurtosis_fw") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters long output includes numeric Folk and Ward parameters", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  result <- gs_parameters(wn2, parameters = "folk_ward", output = "long")

  expect_named(result, c("sample_id", "parameter", "value", "unit", "method"))
  expect_true(all(c("mean_fw_phi", "sorting_fw_phi", "skewness_fw", "kurtosis_fw") %in% result$parameter))
  expect_false(any(c("mean_size_class", "sorting_class") %in% result$parameter))
  expect_true(all(result$method[result$parameter == "mean_fw_phi"] == "folk_ward"))
})

test_that("gs_parameters errors for moments by default", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_parameters(gsd, parameters = "moments"),
    "nonzero retained percent in open-ended classes"
  )
})

test_that("gs_parameters includes moments in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = "moments",
      moments_open_end = "extend_phi"
    ),
    "estimated by extending adjacent phi intervals"
  )

  expect_true(all(c(
    "mean_moment_phi",
    "mean_moment_um",
    "sd_moment_phi",
    "skewness_moment",
    "kurtosis_moment",
    "moments_open_end"
  ) %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters combines moments with other parameter families", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    expect_warning(
      result <- gs_parameters(
        gsd,
        parameters = c("D10", "D50", "indices", "folk_ward", "moments"),
        extrapolate = "warn_linear",
        moments_open_end = "extend_phi"
      ),
      "linearly extrapolating"
    ),
    "estimated by extending adjacent phi intervals"
  )

  expect_true(all(c(
    "D10_um",
    "D50_um",
    "Cu",
    "mean_fw_phi",
    "mean_moment_phi",
    "sd_moment_phi"
  ) %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters long output includes numeric moment rows", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = "moments",
      output = "long",
      moments_open_end = "extend_phi"
    ),
    "estimated by extending adjacent phi intervals"
  )

  expect_true(all(c("mean_moment_phi", "sd_moment_phi", "skewness_moment") %in% result$parameter))
  expect_true(all(result$method[result$parameter == "mean_moment_phi"] == "moments"))
  expect_true(all(result$unit[result$parameter == "sd_moment_phi"] == "phi"))
})

test_that("gs_parameters includes fractions in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(
    gsd,
    parameters = "fractions",
    fraction_scheme = "wentworth_major"
  )

  expect_true(all(c("gravel_percent", "sand_percent", "mud_percent") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters combines fractions with other parameter families", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = c("D50", "indices", "folk_ward", "fractions"),
      extrapolate = "warn_linear",
      fraction_scheme = "wentworth_major"
    ),
    "linearly extrapolating"
  )

  expect_true(all(c(
    "D50_um",
    "Cu",
    "mean_fw_phi",
    "gravel_percent",
    "sand_percent",
    "mud_percent"
  ) %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters long output includes numeric fraction rows", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(
    gsd,
    parameters = "fractions",
    output = "long",
    fraction_scheme = "wentworth_major"
  )

  expect_true(all(c("gravel_percent", "sand_percent", "mud_percent") %in% result$parameter))
  expect_true(all(result$method[result$parameter == "sand_percent"] == "fractions"))
  expect_true(all(result$unit[result$parameter == "sand_percent"] == "percent"))
})
