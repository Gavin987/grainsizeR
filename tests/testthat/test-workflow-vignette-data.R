workflow_read_wide <- function() {
  wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  read_gsd(
    wide_file,
    format = "wide",
    size_col = 1,
    size_unit = "mm",
    value_type = "percent"
  )
}

workflow_read_long <- function() {
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

workflow_repo_root <- function() {
  candidates <- c(
    file.path("..", "00_pkg_src", "grainsizeR"),
    file.path("..", "..", "00_pkg_src", "grainsizeR"),
    ".",
    file.path("..", "..")
  )
  roots <- candidates[file.exists(file.path(candidates, "DESCRIPTION"))]
  expect_gt(length(roots), 0)
  roots[1]
}

test_that("workflow vignette example files exist and read successfully", {
  wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")

  expect_true(file.exists(wide_file))
  expect_true(file.exists(long_file))

  gs_wide <- workflow_read_wide()
  gs_long <- workflow_read_long()

  expect_true(is_gsd_tbl(gs_wide))
  expect_true(is_gsd_tbl(gs_long))
})

test_that("workflow diagnostics return one summary row per sample", {
  gs_wide <- workflow_read_wide()
  gs_long <- workflow_read_long()

  wide_summary <- gs_diagnostics(gs_wide, output = "summary")
  long_summary <- gs_diagnostics(gs_long, output = "summary")

  expect_equal(nrow(wide_summary), length(unique(gs_wide$sample_id)))
  expect_equal(nrow(long_summary), length(unique(gs_long$sample_id)))
  expect_true(all(c("sample_id", "overall_status", "has_warning") %in% names(wide_summary)))
  expect_true(all(c("sample_id", "overall_status", "has_warning") %in% names(long_summary)))
})

test_that("wide diagnostics report dry-sieve open-tail limitations", {
  gs_wide <- workflow_read_wide()
  diag_wide <- gs_diagnostics(gs_wide)

  expect_true(any(diag_wide$check == "open_fine_tail" & diag_wide$status %in% c("info", "warning")))
  expect_true(any(diag_wide$check == "threshold_resolvable" & diag_wide$status == "warning"))
})

test_that("long data have fewer unresolved fine-threshold warnings than wide data", {
  gs_wide <- workflow_read_wide()
  gs_long <- workflow_read_long()
  diag_wide <- gs_diagnostics(gs_wide)
  diag_long <- gs_diagnostics(gs_long)

  fine_thresholds <- c("2 um", "20 um", "50 um", "60 um", "63 um")
  wide_unresolved <- sum(
    diag_wide$check == "threshold_resolvable" &
      diag_wide$parameter %in% fine_thresholds &
      diag_wide$status == "warning"
  )
  long_unresolved <- sum(
    diag_long$check == "threshold_resolvable" &
      diag_long$parameter %in% fine_thresholds &
      diag_long$status == "warning"
  )

  expect_lt(long_unresolved, wide_unresolved)
})

test_that("documented fraction workflows run", {
  gs_wide <- workflow_read_wide()
  gs_long <- workflow_read_long()

  wide_fractions <- gs_fractions_wide(gs_wide, scheme = "wentworth_major")
  long_fractions <- suppressWarnings(gs_fractions_wide(gs_long, scheme = "usda_tt"))

  expect_s3_class(wide_fractions, "data.frame")
  expect_s3_class(long_fractions, "data.frame")
  expect_equal(nrow(wide_fractions), length(unique(gs_wide$sample_id)))
  expect_equal(nrow(long_fractions), length(unique(gs_long$sample_id)))
})

test_that("selected sample reporting and summary plot workflows run", {
  gs_long <- workflow_read_long()
  sample_id <- "WN1_upper"

  summary <- suppressWarnings(gs_parameters(
    gs_long[gs_long$sample_id == sample_id, ],
    parameters = c("d_values", "indices", "folk_ward", "fractions"),
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))
  plot <- suppressWarnings(plot_gradistat_summary(
    gs_long,
    sample_id = sample_id,
    extrapolate = "warn_linear"
  ))

  expect_s3_class(summary, "data.frame")
  expect_equal(nrow(summary), 1)
  expect_s3_class(plot, "ggplot")
})

test_that("workflow examples do not create files", {
  before <- list.files(tempdir(), all.files = TRUE, no.. = TRUE)

  gs_wide <- workflow_read_wide()
  gs_long <- workflow_read_long()
  invisible(gs_diagnostics(gs_wide, output = "summary"))
  invisible(gs_diagnostics(gs_long, output = "summary"))
  invisible(gs_fractions_wide(gs_wide, scheme = "wentworth_major"))
  invisible(suppressWarnings(gs_fractions_wide(gs_long, scheme = "usda_tt")))

  after <- list.files(tempdir(), all.files = TRUE, no.. = TRUE)
  expect_setequal(before, after)
})

test_that("documentation separates table layout from measurement workflow", {
  root <- workflow_repo_root()
  docs <- c(
    file.path(root, "README.md"),
    file.path(root, "vignettes", "table-layouts-and-measurement-workflows.Rmd"),
    file.path(root, "vignettes", "basic-workflow.Rmd"),
    file.path(root, "vignettes", "method-validation.Rmd")
  )
  text <- paste(vapply(docs, function(path) {
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }, character(1)), collapse = "\n")
  text_flat <- gsub("\\s+", " ", text)

  expect_false(grepl("wide data are dry-sieve data", text, fixed = TRUE))
  expect_false(grepl("wide format equals dry sieve", text, fixed = TRUE))
  expect_false(grepl("long format equals hydrometer", text, fixed = TRUE))
  expect_true(grepl("pipette-method", text, ignore.case = TRUE))
  expect_true(grepl("laser-diffraction", text, ignore.case = TRUE))
  expect_true(grepl("cumulative.*converted.*retained bin increments", text_flat, ignore.case = TRUE))
})

test_that("synthetic pipette-like and laser-like wide retained-bin tables can be read", {
  make_file <- function(values, sample_name) {
    path <- tempfile(fileext = ".csv")
    x <- data.frame(
      size = c("2", "0.5", "0.063", "0.02", "0.002", "0.001"),
      sample = values,
      check.names = FALSE
    )
    names(x)[2] <- sample_name
    utils::write.csv(x, path, row.names = FALSE)
    path
  }

  pipette_file <- make_file(c(5, 20, 25, 25, 15, 10), "pipette_sample")
  laser_file <- make_file(c(2, 15, 30, 25, 18, 10), "laser_sample")

  pipette <- read_gsd(
    pipette_file,
    format = "wide",
    size_col = 1,
    size_unit = "mm",
    value_type = "percent"
  )
  laser <- read_gsd(
    laser_file,
    format = "wide",
    size_col = 1,
    size_unit = "mm",
    value_type = "percent"
  )

  pipette_diag <- gs_diagnostics(pipette, thresholds_um = c(2, 20, 50, 63), fraction_schemes = "usda_tt")
  laser_diag <- gs_diagnostics(laser, thresholds_um = c(2, 20, 50, 63), fraction_schemes = "usda_tt")

  expect_true(is_gsd_tbl(pipette))
  expect_true(is_gsd_tbl(laser))
  expect_true(any(pipette_diag$check == "threshold_resolvable" & pipette_diag$parameter == "2 um" & pipette_diag$status == "ok"))
  expect_true(any(laser_diag$check == "threshold_resolvable" & laser_diag$parameter == "20 um" & laser_diag$status == "ok"))
  expect_false(any(grepl("dry-sieve", pipette_diag$message, fixed = TRUE)))
  expect_false(any(grepl("dry-sieve", laser_diag$message, fixed = TRUE)))
})
