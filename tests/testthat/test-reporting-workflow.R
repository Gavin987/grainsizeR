read_reporting_example_gsd <- function() {
  long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  if (!nzchar(long_file)) {
    long_file <- file.path("inst", "extdata", "grain.long.csv")
  }

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

test_that("gs_parameters returns one-row-per-sample reporting table", {
  gs <- read_reporting_example_gsd()

  summary <- suppressWarnings(gs_parameters(
    gs,
    parameters = c("d_values", "indices", "folk_ward"),
    d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
    extrapolate = "warn_linear"
  ))

  expect_s3_class(summary, "data.frame")
  expect_equal(nrow(summary), length(unique(gs$sample_id)))
  expect_true(all(c("D5_um", "D50_um", "D95_um", "Cu", "mean_fw_phi") %in% names(summary)))
})

test_that("gs_parameters reporting table includes gradistat fractions", {
  gs <- read_reporting_example_gsd()

  summary <- suppressWarnings(gs_parameters(
    gs,
    parameters = c("d_values", "indices", "folk_ward", "fractions"),
    d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))

  expect_s3_class(summary, "data.frame")
  expect_equal(nrow(summary), length(unique(gs$sample_id)))
  expect_true(all(c("gravel_percent", "sand_percent", "silt_percent", "clay_percent") %in% names(summary)))
})

test_that("gs_parameters reporting table includes wentworth_major fractions", {
  gs <- read_reporting_example_gsd()

  summary <- suppressWarnings(gs_parameters(
    gs,
    parameters = c("d_values", "indices", "folk_ward", "fractions"),
    d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
    fraction_scheme = "wentworth_major",
    extrapolate = "warn_linear"
  ))

  expect_s3_class(summary, "data.frame")
  expect_equal(nrow(summary), length(unique(gs$sample_id)))
  expect_true(all(c("gravel_percent", "sand_percent", "mud_percent") %in% names(summary)))
})

test_that("gs_parameters reporting table can be exported with base R", {
  gs <- read_reporting_example_gsd()

  summary <- suppressWarnings(gs_parameters(
    gs,
    parameters = c("d_values", "indices", "folk_ward", "fractions"),
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))

  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(summary, tmp, row.names = FALSE)
  roundtrip <- utils::read.csv(tmp, stringsAsFactors = FALSE)

  expect_equal(nrow(roundtrip), nrow(summary))
  expect_true(all(c("sample_id", "D50_um", "Cu") %in% names(roundtrip)))
})

test_that("no dedicated GRADISTAT summary export helper is exported", {
  expect_false(exists("export_gradistat_summary", where = asNamespace("grainsizeR"), inherits = FALSE))
  expect_false("export_gradistat_summary" %in% getNamespaceExports("grainsizeR"))
})
