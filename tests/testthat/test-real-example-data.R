example_gsd_path <- function(file) {
  path <- system.file("extdata", file, package = "grainsizeR")
  if (!nzchar(path)) {
    path <- file.path("..", "..", "inst", "extdata", file)
  }
  path
}

test_that("real example data files are included", {
  expect_true(file.exists(example_gsd_path("grain.long.csv")))
  expect_true(file.exists(example_gsd_path("grain.wide.csv")))
})

test_that("long example input returns a valid gsd_tbl", {
  gsd <- read_gsd(
    example_gsd_path("grain.long.csv"),
    sample_col = "sample",
    size_col = "size",
    value_col = "proportion",
    size_unit = "mm",
    value_type = "proportion",
    format = "long"
  )

  expect_s3_class(gsd, "gsd_tbl")
  expect_equal(length(unique(gsd$sample_id)), 44)
  expect_equal(as.numeric(rowsum(gsd$retained_percent, gsd$sample_id)), rep(100, 44), tolerance = 1e-5)
})

test_that("wide example input returns seven bins per sample with terminal mud bins", {
  gsd <- read_gsd_wide(
    example_gsd_path("grain.wide.csv"),
    size_col = 1,
    size_unit = "mm",
    value_type = "percent"
  )

  expect_s3_class(gsd, "gsd_tbl")
  expect_equal(length(unique(gsd$sample_id)), 44)
  expect_true(all(as.numeric(table(gsd$sample_id)) == 7))
  expect_equal(as.numeric(rowsum(gsd$retained_percent, gsd$sample_id)), rep(100, 44), tolerance = 1e-5)

  final_bins <- gsd[gsd$bin_id == 7, ]
  expect_true(all(final_bins$is_open_lower))
  expect_true(all(is.na(final_bins$size_lower_um)))
  expect_equal(final_bins$size_upper_um, rep(62.5, 44))
  expect_equal(final_bins$raw_size_um, rep(62.5, 44))
})

test_that("long and wide example inputs agree for aggregate fractions", {
  long <- read_gsd(
    example_gsd_path("grain.long.csv"),
    sample_col = "sample",
    size_col = "size",
    value_col = "proportion",
    size_unit = "mm",
    value_type = "proportion"
  )
  wide <- read_gsd_wide(example_gsd_path("grain.wide.csv"), value_type = "percent")

  long_fractions <- gs_fractions_wide(long, scheme = "wentworth_major")
  wide_fractions <- gs_fractions_wide(wide, scheme = "wentworth_major")
  long_fractions <- long_fractions[order(long_fractions$sample_id), ]
  wide_fractions <- wide_fractions[order(wide_fractions$sample_id), ]

  expect_equal(long_fractions$sample_id, wide_fractions$sample_id)
  expect_equal(long_fractions$gravel_percent, wide_fractions$gravel_percent, tolerance = 1e-5)
  expect_equal(long_fractions$sand_percent, wide_fractions$sand_percent, tolerance = 1e-5)
  expect_equal(long_fractions$mud_percent, wide_fractions$mud_percent, tolerance = 1e-5)

  long_finer <- gs_percent_finer(long, sizes = 62.5, size_unit = "um")
  wide_finer <- gs_percent_finer(wide, sizes = 62.5, size_unit = "um")
  long_finer <- long_finer[order(long_finer$sample_id), ]
  wide_finer <- wide_finer[order(wide_finer$sample_id), ]

  expect_equal(long_finer$sample_id, wide_finer$sample_id)
  expect_equal(long_finer$percent_finer, wide_finer$percent_finer, tolerance = 1e-5)
})

test_that("full workflow runs on long example data", {
  gsd <- read_gsd(
    example_gsd_path("grain.long.csv"),
    sample_col = "sample",
    size_col = "size",
    value_col = "proportion",
    size_unit = "mm",
    value_type = "proportion"
  )

  expect_s3_class(gs_percentile(gsd, probs = 50), "tbl_df")
  engineering <- suppressWarnings(gs_engineering(gsd, extrapolate = "warn_linear"))
  folkward <- suppressWarnings(gs_folkward(gsd, extrapolate = "warn_linear"))
  moments <- suppressWarnings(gs_moments(gsd, open_end = "extend_phi"))
  expect_s3_class(gs_fractions_wide(gsd, scheme = "wentworth_major"), "tbl_df")
  expect_s3_class(plot_distribution(gsd), "ggplot")
  expect_s3_class(plot_cumulative(gsd), "ggplot")
  expect_s3_class(plot_fractions(gsd), "ggplot")

  expect_equal(nrow(engineering), 44)
  expect_equal(nrow(folkward), 44)
  expect_equal(nrow(moments), 44)
})
