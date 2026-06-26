read_example_gsd_for_summary <- function() {
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

test_that("plot_gradistat_summary returns ggplot for one sample", {
  gs <- read_example_gsd_for_summary()
  sample <- unique(gs$sample_id)[1]

  p <- suppressWarnings(plot_gradistat_summary(
    gs,
    sample_id = sample,
    extrapolate = "warn_linear"
  ))

  expect_s3_class(p, "ggplot")
})

test_that("plot_gradistat_summary requires sample_id for multiple samples", {
  gs <- read_example_gsd_for_summary()

  expect_error(
    plot_gradistat_summary(gs),
    "sample_id"
  )
})

test_that("plot_gradistat_summary works with supplied sample_id and x scales", {
  gs <- read_example_gsd_for_summary()
  sample <- unique(gs$sample_id)[1]

  for (scale in c("phi", "log10", "linear_um")) {
    p <- suppressWarnings(plot_gradistat_summary(
      gs,
      sample_id = sample,
      x_scale = scale,
      extrapolate = "warn_linear"
    ))
    expect_s3_class(p, "ggplot")
  }
})

test_that("plot_gradistat_summary supports gradistat and wentworth_major fractions", {
  gs <- read_example_gsd_for_summary()
  sample <- unique(gs$sample_id)[1]

  p_gradistat <- suppressWarnings(plot_gradistat_summary(
    gs,
    sample_id = sample,
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))
  p_wentworth <- suppressWarnings(plot_gradistat_summary(
    gs,
    sample_id = sample,
    fraction_scheme = "wentworth_major",
    extrapolate = "warn_linear"
  ))

  expect_s3_class(p_gradistat, "ggplot")
  expect_s3_class(p_wentworth, "ggplot")
})

test_that("plot_gradistat_summary does not require texture polygon data", {
  gs <- read_example_gsd_for_summary()
  sample <- unique(gs$sample_id)[1]

  p <- suppressWarnings(plot_gradistat_summary(
    gs,
    sample_id = sample,
    show_fraction_bands = FALSE,
    show_summary = FALSE
  ))

  expect_s3_class(p, "ggplot")
})

test_that("plot_gradistat_summary does not create files", {
  gs <- read_example_gsd_for_summary()
  sample <- unique(gs$sample_id)[1]
  before <- list.files(tempdir(), all.files = TRUE, no.. = TRUE)

  suppressWarnings(plot_gradistat_summary(
    gs,
    sample_id = sample,
    extrapolate = "warn_linear"
  ))
  after <- list.files(tempdir(), all.files = TRUE, no.. = TRUE)

  expect_setequal(after, before)
})

test_that("plot_gradistat_summary returns plot when D-values are unresolved", {
  x <- data.frame(
    sample_id = rep("open_tail", 7),
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.0625, 0.001),
    retained = c(5, 5, 10, 15, 20, 20, 25)
  )
  gs <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  p <- suppressWarnings(plot_gradistat_summary(gs, show_d_values = TRUE, extrapolate = "error"))
  expect_s3_class(p, "ggplot")
})

test_that("plot_gradistat_summary adds no dependencies beyond ggplot2", {
  candidates <- c(
    "DESCRIPTION",
    file.path("..", "..", "DESCRIPTION"),
    file.path("..", "00_pkg_src", "grainsizeR", "DESCRIPTION"),
    file.path("..", "..", "00_pkg_src", "grainsizeR", "DESCRIPTION")
  )
  desc_file <- candidates[file.exists(candidates)][1]
  expect_false(is.na(desc_file))
  desc <- read.dcf(desc_file)
  imports <- paste(desc[1, "Imports"], collapse = " ")

  expect_true(grepl("ggplot2", imports, fixed = TRUE))
  expect_false(grepl("patchwork|cowplot|gridExtra|ggtern|Ternary", imports))
})
