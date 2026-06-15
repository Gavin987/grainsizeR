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

test_that("gs_parameters combines D-values and engineering indices", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(gsd, parameters = c("D10", "D30", "engineering"))

  expect_true(all(c("D10_um", "D30_um", "Cu", "Cc", "fine_content_percent") %in% names(result)))
  expect_equal(nrow(result), 2)
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
    parameters = c("D10", "D30", "engineering"),
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
    gs_parameters(gsd, parameters = c("D10", "folk_ward")),
    "Unsupported parameters"
  )
})
