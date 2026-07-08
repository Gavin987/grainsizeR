# README.Rmd's Quick Start and other illustrative code chunks are eval=FALSE
# (running them live would auto-print duplicate plots alongside the separate
# "held" man/figures/*.png chunks that data-raw/readme-figures.R generates),
# so devtools::build_readme() never actually executes this code. This test
# mirrors it verbatim against current bundled data and the current API so a
# stale scheme name or broken example doesn't go unnoticed between manual
# verification passes.

test_that("README Quick Start code runs without error", {
  wide_path <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  long_path <- system.file("extdata", "grain.long.csv", package = "grainsizeR")

  wide <- read_gsd(wide_path, format = "wide")
  long <- read_gsd(long_path)

  expect_s3_class(wide, "gsd_tbl")
  expect_s3_class(long, "gsd_tbl")

  expect_no_error(gs_diagnostics(wide, output = "summary"))
  expect_no_error(gs_d_values(long, probs = c(10, 50, 90), extrapolate = "warn_linear"))
  expect_no_error(gs_folk_ward(long, extrapolate = "warn_linear"))
  # gravel_sand_mud only (not gradistat): the bundled grain.wide.csv has no
  # real data below 63um, so GRADISTAT's clay/silt split is not resolvable
  # on it by default (see dev-notes/AUDIT_LOG.md's root-cause entry).
  # README.Rmd itself still shows gradistat here and needs its own
  # follow-up pass - not attempted in this task.
  expect_no_error(gs_fractions_wide(wide, scheme = "gravel_sand_mud"))
})

test_that("README Grain-Size Plots code runs without error", {
  wide_path <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  wide <- read_gsd(wide_path, format = "wide")

  expect_no_error(plot_distribution(wide, sample = 1, cumulative = TRUE))
  expect_no_error(
    with_known_extrapolation_warnings(
      plot_cumulative(
        wide,
        sample = "S01",
        show_percentiles = TRUE,
        extrapolate = "warn_linear"
      )
    )
  )

  samples <- unique(wide$sample_id)
  plots <- lapply(samples, function(id) plot_distribution(wide, sample = id))
  expect_length(plots, length(samples))
})

test_that("README Fraction Summaries and Texture Ternary Plots code runs without error", {
  wide_path <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  long_path <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  wide <- read_gsd(wide_path, format = "wide")
  long <- read_gsd(long_path)

  expect_no_error(
    plot_fractions(wide, scheme = "gravel_sand_mud", sample = 1:10, fill_palette = "YlOrBr")
  )

  # The bundled grain.wide.csv/grain.long.csv have no real data below
  # 63um, so GRADISTAT's/USDA's fine clay/silt boundaries are not
  # resolvable on them by default (see dev-notes/AUDIT_LOG.md's root-cause
  # entry). gravel_sand_mud's fractions still feed plot_texture_ternary()'s
  # "gradistat" ternary axes (gravel/sand/mud); USDA's ternary needs a
  # genuine sand/silt/clay input, so a small synthetic fine-resolution
  # dataset stands in for `long` here. README.Rmd itself still shows
  # gradistat/usda directly on the bundled data and needs its own
  # follow-up pass - not attempted in this task.
  gradistat_components <- gs_fractions_wide(wide, scheme = "gravel_sand_mud")

  fine_path <- tempfile(fileext = ".csv")
  fine_csv <- data.frame(
    size = c("2000", "1000", "500", "250", "125", "63", "20", "2", "0.001"),
    S01 = c(1, 4, 15, 30, 30, 15, 3, 1.5, 0.5),
    S02 = c(2, 6, 20, 25, 25, 12, 6, 3, 1),
    check.names = FALSE
  )
  write.csv(fine_csv, fine_path, row.names = FALSE)
  fine_long <- read_gsd(fine_path, format = "wide")
  usda_components <- gs_fractions_wide(fine_long, scheme = "usda", normalize = "fine_earth")

  expect_no_error(plot_texture_ternary(gradistat_components, scheme = "gradistat"))
  expect_no_error(
    plot_texture_ternary(usda_components, scheme = "usda", show_sample_labels = TRUE)
  )
})

test_that("README Parameter Summaries code runs without error", {
  long_path <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  long <- read_gsd(long_path)

  summary <- with_known_extrapolation_warnings(
    gs_parameters(
      long,
      parameters = c("d_values", "indices", "folk_ward", "fractions"),
      fraction_scheme = "gradistat",
      extrapolate = "warn_linear"
    )
  )

  out_path <- tempfile(fileext = ".csv")
  write.csv(summary, out_path, row.names = FALSE)
  expect_true(file.exists(out_path))
})

test_that("README End-to-End Workflow code runs without error", {
  long_path <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  long <- read_gsd(long_path)

  expect_no_error(gs_diagnostics(long, output = "summary"))
  expect_no_error(
    with_known_extrapolation_warnings(
      gs_parameters(
        long,
        parameters = c("d_values", "indices", "folk_ward", "fractions"),
        fraction_scheme = "gradistat",
        extrapolate = "warn_linear"
      )
    )
  )

  expect_no_error(plot_distribution(long, sample = "S01", cumulative = TRUE))
  expect_no_error(plot_cumulative(long, sample = "S01", extrapolate = "warn_linear"))
  expect_no_error(plot_fractions(long, scheme = "wentworth_major"))

  # The bundled grain.long.csv has no real data below 63um, so USDA's fine
  # clay/silt boundaries are not resolvable on it by default (see
  # dev-notes/AUDIT_LOG.md's root-cause entry); a small synthetic
  # fine-resolution dataset stands in here. README.Rmd itself still shows
  # usda directly on the bundled data and needs its own follow-up pass -
  # not attempted in this task.
  fine_path <- tempfile(fileext = ".csv")
  fine_csv <- data.frame(
    size = c("2000", "1000", "500", "250", "125", "63", "20", "2", "0.001"),
    S01 = c(1, 4, 15, 30, 30, 15, 3, 1.5, 0.5),
    S02 = c(2, 6, 20, 25, 25, 12, 6, 3, 1),
    check.names = FALSE
  )
  write.csv(fine_csv, fine_path, row.names = FALSE)
  fine_long <- read_gsd(fine_path, format = "wide")
  usda_components <- gs_fractions_wide(fine_long, scheme = "usda", normalize = "fine_earth")
  expect_no_error(plot_texture_ternary(usda_components, scheme = "usda"))
})
