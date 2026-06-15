test_that("gs_cumulative returns finite boundaries for each sample", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  curve <- gs_cumulative(gsd)

  expect_s3_class(curve, "tbl_df")
  expect_named(curve, c(
    "sample_id",
    "boundary_id",
    "boundary_um",
    "boundary_mm",
    "boundary_phi",
    "percent_finer",
    "percent_coarser"
  ))
  expect_equal(sum(curve$sample_id == "WN1"), 6)
  expect_equal(sum(curve$sample_id == "WN2"), 10)
})

test_that("gs_cumulative calculates percent finer at finite boundaries", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  curve <- gs_cumulative(gsd)

  wn1 <- curve[curve$sample_id == "WN1", ]
  wn2 <- curve[curve$sample_id == "WN2", ]

  expect_equal(wn1$percent_finer[wn1$boundary_um == 2000], 97.6447387, tolerance = 1e-7)
  expect_equal(wn1$percent_finer[wn1$boundary_um == 1000], 95.0290221, tolerance = 1e-7)
  expect_equal(wn1$percent_finer[wn1$boundary_um == 62.5], 5.5811877, tolerance = 1e-7)
  expect_equal(wn2$percent_finer[wn2$boundary_um == 62.5], 14.3772842, tolerance = 1e-7)
  expect_equal(wn2$percent_finer[wn2$boundary_um == 13.330233], 2.9952675, tolerance = 1e-7)
})
