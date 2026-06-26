test_that("read_gsd_wide reads wide grain-size input", {
  path <- tempfile(fileext = ".csv")
  wide <- data.frame(
    size = c("2", "1", "0.5", "0.25", "0.125", "0.0625", "<0.0625"),
    A = c(2, 3, 5, 20, 20, 35, 15),
    B = c(1, 2, 7, 25, 30, 25, 10),
    check.names = FALSE
  )
  write.csv(wide, path, row.names = FALSE)

  gsd <- read_gsd_wide(path, size_col = 1, value_type = "percent")

  expect_s3_class(gsd, "gsd_tbl")
  expect_equal(unique(gsd$sample_id), c("A", "B"))
  expect_equal(as.numeric(rowsum(gsd$retained_percent, gsd$sample_id)), c(100, 100))

  sample_a <- gsd[gsd$sample_id == "A", ]
  expect_equal(nrow(sample_a), 7)
  expect_equal(sample_a$raw_size_um, c(2000, 1000, 500, 250, 125, 62.5, 62.5))
  expect_equal(sample_a$size_upper_um[nrow(sample_a)], 62.5)
  expect_true(sample_a$is_open_lower[nrow(sample_a)])
  expect_true(is.na(sample_a$size_lower_um[nrow(sample_a)]))
})

test_that("read_gsd dispatches to read_gsd_wide for wide input", {
  path <- tempfile(fileext = ".csv")
  wide <- data.frame(
    size = c("2", "1", "0.5", "0.25", "0.125", "0.0625", "<0.0625"),
    A = c(2, 3, 5, 20, 20, 35, 15),
    check.names = FALSE
  )
  write.csv(wide, path, row.names = FALSE)

  direct <- read_gsd_wide(path, size_col = 1, value_type = "percent")
  dispatched <- read_gsd(path, size_col = 1, value_type = "percent", format = "wide")

  expect_equal(dispatched, direct)
})

test_that("gs_percentile does not silently calculate inside open fine tails", {
  path <- tempfile(fileext = ".csv")
  wide <- data.frame(
    size = c("2", "1", "0.5", "0.25", "0.125", "0.0625", "<0.0625"),
    A = c(2, 3, 5, 20, 20, 35, 15),
    check.names = FALSE
  )
  write.csv(wide, path, row.names = FALSE)
  gsd <- read_gsd_wide(path, value_type = "percent")

  expect_error(
    gs_percentile(gsd, probs = 5, extrapolate = "error"),
    "outside the finite boundary curve range"
  )

  expect_warning(
    result <- gs_percentile(gsd, probs = 5, extrapolate = "warn_linear"),
    "linearly extrapolating"
  )
  expect_true(result$extrapolated)
})
