d_spread_test_gsd <- function() {
  as_gsd_tbl(
    data.frame(
      sample_id = rep(c("A", "B"), each = 6),
      size_mm = rep(c(4, 2, 1, 0.5, 0.25, 0.125), 2),
      retained = c(
        5, 10, 20, 30, 25, 10,
        10, 15, 25, 20, 20, 10
      )
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
}

d_spread_test_root <- function() {
  candidates <- c(
    ".",
    file.path("..", ".."),
    file.path("..", "00_pkg_src", "grainsizeR"),
    file.path("..", "..", "00_pkg_src", "grainsizeR")
  )
  root <- candidates[file.exists(file.path(candidates, "DESCRIPTION"))][1]
  expect_false(is.na(root))
  root
}

test_that("gs_d_spread is exported", {
  expect_true("gs_d_spread" %in% getNamespaceExports("grainsizeR"))
})

test_that("gs_d_spread returns one row per sample with required columns", {
  result <- gs_d_spread(d_spread_test_gsd(), extrapolate = "warn_linear")
  required <- c(
    "sample_id", "D10", "D25", "D50", "D75", "D90", "d_value_unit",
    "D90_D10_ratio", "D90_minus_D10", "D75_D25_ratio", "D75_minus_D25",
    "D90_D10_log_ratio", "D75_D25_log_ratio", "quartile_deviation_phi",
    "any_extrapolated"
  )

  expect_equal(nrow(result), 2)
  expect_true(all(required %in% names(result)))
  expect_equal(result$sample_id, c("A", "B"))
})

test_that("gs_d_spread descriptors are derived from metric D-values", {
  result <- gs_d_spread(d_spread_test_gsd(), scale = "um", extrapolate = "warn_linear")

  expect_equal(result$D90_D10_ratio, result$D90 / result$D10)
  expect_equal(result$D90_minus_D10, result$D90 - result$D10)
  expect_equal(result$D75_D25_ratio, result$D75 / result$D25)
  expect_equal(result$D75_minus_D25, result$D75 - result$D25)
  expect_equal(result$D90_D10_log_ratio, log10(result$D90 / result$D10))
  expect_equal(result$D75_D25_log_ratio, log10(result$D75 / result$D25))
})

test_that("gs_d_spread can report metric differences in millimeters", {
  um <- gs_d_spread(d_spread_test_gsd(), scale = "um", extrapolate = "warn_linear")
  mm <- gs_d_spread(d_spread_test_gsd(), scale = "mm", extrapolate = "warn_linear")

  expect_equal(mm$d_value_unit, rep("mm", nrow(mm)))
  expect_equal(mm$D10, um_to_mm(um$D10))
  expect_equal(mm$D90_minus_D10, um_to_mm(um$D90_minus_D10))
  expect_equal(mm$D90_D10_ratio, um$D90_D10_ratio)
})

test_that("gs_d_spread follows existing open-tail extrapolation policy", {
  gsd <- as_gsd_tbl(
    data.frame(
      sample_id = rep("A", 4),
      size_mm = c(2, 1, 0.5, 0.25),
      retained = c(80, 10, 5, 5)
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )

  expect_error(gs_d_spread(gsd, extrapolate = "error"), "fall outside")
  expect_warning(
    result <- gs_d_spread(gsd, extrapolate = "warn_linear"),
    "linearly extrapolating"
  )
  expect_true(result$any_extrapolated)
})

test_that("gs_d_spread reports the Krumbein (1938) quartile deviation in phi units", {
  gsd <- d_spread_test_gsd()
  result <- gs_d_spread(gsd, scale = "um", extrapolate = "warn_linear")
  phi <- gs_d_values(
    gsd,
    probs = c(25, 75),
    output_unit = "phi",
    extrapolate = "warn_linear"
  )
  phi_wide <- split(phi, phi$sample_id, drop = TRUE)
  expected <- vapply(phi_wide, function(one) {
    values <- stats::setNames(one$grain_size_phi, paste0("D", one$percentile))
    (values[["D25"]] - values[["D75"]]) / 2
  }, numeric(1))

  expect_true("quartile_deviation_phi" %in% names(result))
  expect_equal(result$quartile_deviation_phi, unname(expected[result$sample_id]))
  expect_true(all(result$quartile_deviation_phi > 0))
})

test_that("gs_d_spread rejects phi spread output explicitly", {
  expect_error(
    gs_d_spread(d_spread_test_gsd(), scale = "phi"),
    "'arg' should be one of"
  )
})

test_that("gs_parameters can include D-spread descriptors", {
  result <- gs_parameters(
    d_spread_test_gsd(),
    parameters = "d_spread",
    extrapolate = "warn_linear"
  )

  expect_true(all(c("D90_D10_ratio", "D90_minus_D10", "D75_D25_ratio", "D75_minus_D25") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("D-spread support adds no package dependency", {
  description <- read.dcf(file.path(d_spread_test_root(), "DESCRIPTION"))
  dependency_fields <- paste(description[, intersect(colnames(description), c("Depends", "Imports", "Suggests"))], collapse = "\n")
  expect_false(grepl("soiltexture", dependency_fields, ignore.case = TRUE))
})
