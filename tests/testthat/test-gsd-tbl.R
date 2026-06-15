test_that("as_gsd_tbl returns a tibble-based gsd_tbl", {
  x <- data.frame(
    sample_id = c("A", "A", "A"),
    size_mm = c(2, 1, 0.001),
    retained_proportion = c(0.2, 0.3, 0.5)
  )

  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained_proportion)

  expect_s3_class(gsd, "gsd_tbl")
  expect_s3_class(gsd, "tbl_df")
  expect_true(is_gsd_tbl(gsd))
  expect_named(gsd, c(
    "sample_id",
    "bin_id",
    "raw_size_um",
    "size_lower_um",
    "size_upper_um",
    "size_mid_um",
    "size_mid_phi",
    "retained_percent",
    "cum_finer_percent",
    "cum_coarser_percent",
    "is_open_lower",
    "is_open_upper",
    "measurement_method"
  ))
})

test_that("validate_gsd_tbl accepts valid data and rejects non-gsd objects", {
  x <- data.frame(
    sample_id = c("A", "A"),
    size_mm = c(1, 0.001),
    retained_proportion = c(0.4, 0.6)
  )

  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained_proportion)

  expect_invisible(validate_gsd_tbl(gsd))
  expect_error(validate_gsd_tbl(data.frame()), "`x` must be a gsd_tbl")
})
