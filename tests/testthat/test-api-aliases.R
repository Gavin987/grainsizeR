test_that("gs_d_values matches gs_percentile", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  preferred <- gs_d_values(gsd, probs = c(10, 50), interpolation_scale = "phi")
  compatible <- gs_percentile(gsd, probs = c(10, 50), interpolation_scale = "phi")

  expect_equal(preferred, compatible)
})

test_that("gs_grain_size_indices matches gs_engineering", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  preferred <- gs_grain_size_indices(gsd)
  compatible <- gs_engineering(gsd)

  expect_equal(preferred, compatible)
})

test_that("gs_folk_ward matches gs_folkward", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  preferred <- gs_folk_ward(wn2)
  compatible <- gs_folkward(wn2)

  expect_equal(preferred, compatible)
})

test_that("plot_texture_triangle returns a ggplot object", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    plot <- plot_texture_triangle(gsd, scheme = "gradistat"),
    "dropped"
  )
  expect_s3_class(plot, "ggplot")
})

test_that("gs_parameters supports preferred and compatibility index tokens", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  preferred <- gs_parameters(gsd, parameters = "indices")
  compatible <- gs_parameters(gsd, parameters = "engineering")

  expect_equal(preferred, compatible)
  expect_true(all(c("Cu", "Cc", "fine_content_percent") %in% names(preferred)))
})

test_that("scale remains a compatibility alias for interpolation_scale", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  d_old <- gs_d_values(gsd, probs = 50, scale = "log_um")
  d_new <- gs_d_values(gsd, probs = 50, interpolation_scale = "log_um")
  finer_old <- gs_percent_finer(gsd, sizes = 62.5, scale = "linear_um")
  finer_new <- gs_percent_finer(gsd, sizes = 62.5, interpolation_scale = "linear_um")

  expect_equal(d_old, d_new)
  expect_equal(finer_old, finer_new)
})
