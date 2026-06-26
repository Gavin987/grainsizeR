known_result_gsd <- function() {
  x <- data.frame(
    sample_id = "known",
    size_mm = c(2, 1, 0.0625, 0.001),
    retained = c(10, 20, 30, 40)
  )
  as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")
}

test_that("synthetic retained percentages sum to 100", {
  gsd <- known_result_gsd()

  totals <- tapply(gsd$retained_percent, gsd$sample_id, sum)
  expect_equal(as.numeric(totals), 100)
})

test_that("synthetic cumulative finer values are monotonic by boundary", {
  curve <- gs_cumulative(known_result_gsd())
  ordered <- curve[order(curve$boundary_um), ]

  expect_true(all(diff(ordered$percent_finer) >= 0))
  expect_equal(ordered$percent_finer, c(40, 70, 90))
})

test_that("percent finer is known at exact finite boundaries", {
  result <- gs_percent_finer(
    known_result_gsd(),
    sizes = c(62.5, 1000, 2000),
    size_unit = "um"
  )

  expect_equal(result$percent_finer, c(40, 70, 90))
  expect_false(any(result$extrapolated))
})

test_that("D-values are known when percentiles fall on finite boundaries", {
  result <- gs_d_values(known_result_gsd(), probs = c(40, 70, 90))

  expect_equal(result$grain_size_um, c(62.5, 1000, 2000))
  expect_false(any(result$extrapolated))
})

test_that("Wentworth major fractions have known synthetic values", {
  fractions <- gs_fractions(known_result_gsd(), scheme = "wentworth_major")
  values <- stats::setNames(fractions$percent, fractions$component)

  expect_equal(values[["gravel"]], 10)
  expect_equal(values[["sand"]], 50)
  expect_equal(values[["mud"]], 40)
})

test_that("open-tail D-values require explicit extrapolation", {
  gsd <- known_result_gsd()

  expect_error(
    gs_d_values(gsd, probs = 5, extrapolate = "error"),
    "fall outside"
  )

  expect_warning(
    result <- gs_d_values(gsd, probs = 5, extrapolate = "warn_linear"),
    "linearly extrapolating"
  )
  expect_true(result$extrapolated)
})
