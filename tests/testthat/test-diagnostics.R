diagnostics_example_long <- function() {
  long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  read_gsd(
    long_file,
    format = "long",
    sample_col = "sample",
    size_col = "size",
    value_col = "proportion",
    size_unit = "mm",
    value_type = "proportion"
  )
}

diagnostics_example_wide <- function() {
  wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  read_gsd(
    wide_file,
    format = "wide",
    size_col = 1,
    size_unit = "mm",
    value_type = "percent"
  )
}

diagnostics_synthetic <- function() {
  x <- data.frame(
    sample_id = rep(c("bounded_like", "dry_sieve"), each = 5),
    size_mm = rep(c(2, 0.5, 0.063, 0.01, 0.001), 2),
    retained = c(5, 20, 30, 30, 15, 5, 35, 40, 15, 5)
  )
  as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")
}

diagnostics_dry_sieve <- function() {
  x <- data.frame(
    sample_id = "dry_sieve_only",
    size_mm = c(2, 0.5, 0.063, 0.001),
    retained = c(5, 35, 40, 20)
  )
  as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")
}

test_that("gs_diagnostics returns required long, summary, and wide schemas", {
  x <- diagnostics_synthetic()
  diag <- gs_diagnostics(x)

  required <- c(
    "sample_id",
    "check",
    "status",
    "severity",
    "value",
    "expected",
    "parameter",
    "message",
    "recommendation"
  )
  expect_s3_class(diag, "data.frame")
  expect_true(all(required %in% names(diag)))
  expect_true(all(diag$status %in% c("ok", "warning", "error", "info", "not_applicable")))
  expect_true(all(diag$severity %in% c("none", "low", "medium", "high")))

  summary <- gs_diagnostics(x, output = "summary")
  expect_true(all(c("sample_id", "n_ok", "n_warning", "n_error", "n_info", "overall_status") %in% names(summary)))
  expect_equal(nrow(summary), length(unique(x$sample_id)))

  wide <- gs_diagnostics(x, output = "wide")
  expect_true("retained_total_status" %in% names(wide))
  expect_equal(nrow(wide), length(unique(x$sample_id)))
})

test_that("valid synthetic data produce mostly ok diagnostics", {
  x <- diagnostics_synthetic()
  diag <- gs_diagnostics(x, thresholds_um = c(10, 63, 2000), fraction_schemes = "wentworth_major")

  bounded <- diag[diag$sample_id == "bounded_like", ]
  expect_gt(sum(bounded$status == "ok"), sum(bounded$status == "warning"))
  expect_true(any(bounded$check == "retained_total" & bounded$status == "ok"))
})

test_that("retained total and negative retained values are flagged", {
  x <- diagnostics_synthetic()
  bad_total <- x
  total_index <- which(bad_total$sample_id == "bounded_like")[1]
  bad_total$retained_percent[total_index] <- 25

  diag_total <- gs_diagnostics(bad_total, d_values = 50, thresholds_um = 63, fraction_schemes = "wentworth_major")
  total_row <- diag_total[diag_total$sample_id == "bounded_like" & diag_total$check == "retained_total", ]
  expect_equal(total_row$status, "warning")

  negative <- x
  negative_index <- which(negative$sample_id == "bounded_like")[1]
  negative$retained_percent[negative_index] <- -1
  diag_negative <- gs_diagnostics(negative, d_values = 50, thresholds_um = 63, fraction_schemes = "wentworth_major")
  negative_row <- diag_negative[diag_negative$sample_id == "bounded_like" & diag_negative$check == "negative_values", ]
  expect_equal(negative_row$status, "error")
})

test_that("open fine tails and unresolved fine-end calculations are reported", {
  dry <- diagnostics_dry_sieve()

  diag <- gs_diagnostics(
    dry,
    d_values = c(5, 50),
    thresholds_um = c(2, 63),
    fraction_schemes = c("wentworth_major", "usda_tt")
  )

  expect_true(any(diag$check == "open_fine_tail" & diag$status == "info"))
  expect_true(any(diag$check == "d_value_resolvable" & diag$parameter == "D5" & diag$status == "warning"))
  expect_true(any(diag$check == "threshold_resolvable" & diag$parameter == "2 um" & diag$status == "warning"))
  expect_true(any(diag$check == "fraction_scheme_resolvable" & diag$parameter == "usda_tt" & diag$status == "ok"))
})

test_that("diagnostics do not silently extrapolate by default", {
  dry <- diagnostics_dry_sieve()

  diag_error <- gs_diagnostics(dry, d_values = 5, thresholds_um = 2, fraction_schemes = "usda_tt")
  diag_warn <- gs_diagnostics(dry, d_values = 5, thresholds_um = 2, fraction_schemes = "usda_tt", extrapolate = "warn_linear")

  expect_true(any(diag_error$status == "warning"))
  expect_true(any(diag_warn$check == "threshold_resolvable" & diag_warn$status == "warning" & diag_warn$severity == "low"))
})

test_that("diagnostics run on real long and wide example data", {
  gs_long <- diagnostics_example_long()
  gs_wide <- diagnostics_example_wide()

  diag_long <- gs_diagnostics(gs_long)
  diag_wide <- gs_diagnostics(gs_wide)

  required <- c("sample_id", "check", "status", "severity", "value", "expected", "parameter", "message", "recommendation")
  expect_true(all(required %in% names(diag_long)))
  expect_true(all(required %in% names(diag_wide)))
  expect_true(any(diag_wide$check == "open_fine_tail" & diag_wide$status %in% c("info", "warning")))

  fine_thresholds <- c("2 um", "20 um", "50 um", "60 um", "63 um")
  long_unresolved <- sum(
    diag_long$check == "threshold_resolvable" &
      diag_long$parameter %in% fine_thresholds &
      diag_long$status == "warning"
  )
  wide_unresolved <- sum(
    diag_wide$check == "threshold_resolvable" &
      diag_wide$parameter %in% fine_thresholds &
      diag_wide$status == "warning"
  )
  expect_lt(long_unresolved, wide_unresolved)
})

test_that("selected real sample diagnostics and unresolved tails are available", {
  gs_long <- diagnostics_example_long()
  sample_x <- gs_long[gs_long$sample_id == "WN1_upper", ]
  diag <- gs_diagnostics(sample_x)

  expect_s3_class(diag, "data.frame")
  expect_true(all(diag$sample_id == "WN1_upper"))
  expect_true(any(diag$check == "d_value_resolvable"))

  all_diag <- gs_diagnostics(gs_long)
  expect_true(any(all_diag$check %in% c("d_value_resolvable", "threshold_resolvable") & all_diag$status == "warning"))
})

test_that("diagnostics do not create files", {
  before <- list.files(tempdir(), all.files = TRUE, no.. = TRUE)
  x <- diagnostics_synthetic()
  invisible(gs_diagnostics(x, output = "summary"))
  after <- list.files(tempdir(), all.files = TRUE, no.. = TRUE)

  expect_setequal(before, after)
})
