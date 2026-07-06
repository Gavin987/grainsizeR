threshold_interpolation_fixture <- function() {
  data.frame(
    sample_id = c(rep("A", 8), rep("B", 7)),
    size_mm = c(
      2, 0.125, 0.075, 0.045, 0.010, 0.003, 0.0015, 0.0005,
      2, 0.125, 0.075, 0.045, 0.010, 0.003, 0.0005
    ),
    retained_percent = c(
      4, 8, 10, 12, 18, 16, 14, 18,
      3, 7, 11, 14, 21, 20, 24
    )
  )
}

test_that("gs_percent_finer interpolates arbitrary bracketed thresholds", {
  gsd <- as_gsd_tbl(
    threshold_interpolation_fixture(),
    sample_id,
    size_mm,
    retained_percent,
    value_type = "percent"
  )
  sample_a <- gsd[gsd$sample_id == "A", ]

  result <- gs_percent_finer(sample_a, sizes = c(60, 2), size_unit = "um")

  expect_equal(result$threshold_um, c(60, 2))
  expect_true(all(is.finite(result$percent_finer)))
  expect_false(any(result$extrapolated))
  expect_false(any(result$threshold_um %in% sample_a$raw_size_um))
})

test_that("gs_percent_finer keeps thresholds in open fine tails unresolved by default", {
  gsd <- as_gsd_tbl(
    threshold_interpolation_fixture(),
    sample_id,
    size_mm,
    retained_percent,
    value_type = "percent"
  )
  sample_b <- gsd[gsd$sample_id == "B", ]

  expect_error(
    gs_percent_finer(sample_b, sizes = 2, size_unit = "um", extrapolate = "error"),
    "outside the finite boundary size range"
  )

  expect_warning(
    result <- gs_percent_finer(sample_b, sizes = 2, size_unit = "um", extrapolate = "warn_linear"),
    "linearly extrapolating"
  )
  expect_true(result$extrapolated)
  expect_true(is.finite(result$percent_finer))
})

test_that("gs_fractions interpolates scheme boundaries when bracketed", {
  gsd <- as_gsd_tbl(
    threshold_interpolation_fixture(),
    sample_id,
    size_mm,
    retained_percent,
    value_type = "percent"
  )
  sample_a <- gsd[gsd$sample_id == "A", ]

  uk <- gs_fractions(sample_a, scheme = "uk_ssew")
  usda <- gs_fractions(sample_a, scheme = "usda")
  isss <- gs_fractions(sample_a, scheme = "isss")

  for (result in list(uk, usda, isss)) {
    soil <- result[result$component %in% c("sand", "silt", "clay"), ]
    expect_true(all(soil$resolved))
    expect_true(all(is.finite(soil$percent)))
  }
})

test_that("gs_fractions requires explicit extrapolation for sample B's open fine tail", {
  # Sample B's finest measured boundary is 3um, with nonzero pan mass
  # (24%) below it; USDA's clay boundary (2um) falls inside that open
  # tail with no nominal-equivalence match, so it is genuinely unresolved
  # by default (see dev-notes/AUDIT_LOG.md's root-cause entry) - this
  # must not silently resolve to 0 percent (the pre-fix behavior).
  gsd <- as_gsd_tbl(
    threshold_interpolation_fixture(),
    sample_id,
    size_mm,
    retained_percent,
    value_type = "percent"
  )
  sample_b <- gsd[gsd$sample_id == "B", ]

  expect_error(
    gs_fractions(sample_b, scheme = "usda", unresolved = "warn_na"),
    "open-ended \\(pan\\) class with nonzero retained mass"
  )

  result <- suppressWarnings(gs_fractions(sample_b, scheme = "usda", unresolved = "warn_na", extrapolate = "warn_linear"))
  expect_true(is.finite(result$percent[result$component == "clay"]))
  expect_false(is.na(result$percent[result$component == "silt"]))
  expect_false(is.na(result$percent[result$component == "sand"]))
  expect_equal(sum(result$percent), 100, tolerance = 1e-8)

  expect_s3_class(
    suppressWarnings(gs_fractions(sample_b, scheme = "usda", unresolved = "error", extrapolate = "warn_linear")),
    "tbl_df"
  )
})

test_that("real example data resolves available arbitrary thresholds and closes fractions", {
  path <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  if (!nzchar(path)) {
    path <- file.path("..", "..", "inst", "extdata", "grain.long.csv")
  }
  gsd <- read_gsd(
    path,
    sample_col = "sample",
    size_col = "size",
    value_col = "proportion",
    size_unit = "mm",
    value_type = "proportion"
  )

  sample_results <- lapply(split(gsd, gsd$sample_id), function(sample_x) {
    tryCatch(
      gs_percent_finer(sample_x, sizes = c(20, 50, 60, 63), size_unit = "um"),
      error = function(err) NULL
    )
  })
  resolved_results <- Filter(Negate(is.null), sample_results)

  expect_gt(length(resolved_results), 0)
  expect_true(all(vapply(resolved_results, function(result) {
    all(result$threshold_um %in% c(20, 50, 60, 63)) &&
      all(is.finite(result$percent_finer)) &&
      !any(result$extrapolated)
  }, logical(1))))

  # grain.long.csv has no real data below 63um, so USDA's fine clay/silt
  # boundaries are genuinely unresolved by default here (see
  # dev-notes/AUDIT_LOG.md's root-cause entry) - extrapolate = "warn_linear"
  # is required, matching the fix's coordinated behavior with
  # gs_percent_finer() above.
  fractions <- suppressWarnings(gs_fractions(gsd, scheme = "usda", unresolved = "warn_na", extrapolate = "warn_linear"))
  expect_false(any(is.na(fractions$percent)))
  expect_equal(as.numeric(rowsum(fractions$percent, fractions$sample_id)), rep(100, length(unique(fractions$sample_id))), tolerance = 1e-8)

  sand <- fractions[fractions$component == "sand", ]
  expect_true(any(!is.na(sand$percent)))
})
