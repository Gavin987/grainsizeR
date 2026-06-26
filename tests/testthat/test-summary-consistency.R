read_summary_consistency_gsd <- function() {
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

match_by_sample <- function(x, y) {
  y[match(x$sample_id, y$sample_id), , drop = FALSE]
}

test_that("gs_parameters d_values agree with gs_d_values", {
  gs <- read_summary_consistency_gsd()
  probs <- c(10, 50, 90)

  params <- suppressWarnings(gs_parameters(
    gs,
    parameters = "d_values",
    d_values = probs,
    extrapolate = "warn_linear"
  ))
  direct <- suppressWarnings(gs_d_values(gs, probs = probs, extrapolate = "warn_linear"))

  for (prob in probs) {
    values <- direct$grain_size_um[direct$percentile == prob]
    names(values) <- direct$sample_id[direct$percentile == prob]
    expect_equal(params[[paste0("D", prob, "_um")]], unname(values[params$sample_id]), tolerance = 1e-8)
  }
})

test_that("gs_parameters indices agree with gs_grain_size_indices", {
  gs <- read_summary_consistency_gsd()

  params <- suppressWarnings(gs_parameters(gs, parameters = "indices", extrapolate = "warn_linear"))
  direct <- suppressWarnings(gs_grain_size_indices(gs, extrapolate = "warn_linear"))
  direct <- match_by_sample(params, direct)

  for (col in intersect(names(params), names(direct))) {
    if (is.numeric(params[[col]])) {
      expect_equal(params[[col]], direct[[col]], tolerance = 1e-8, info = col)
    }
  }
})

test_that("gs_parameters Folk and Ward values agree with gs_folk_ward", {
  gs <- read_summary_consistency_gsd()

  params <- suppressWarnings(gs_parameters(gs, parameters = "folk_ward", extrapolate = "warn_linear"))
  direct <- suppressWarnings(gs_folk_ward(gs, extrapolate = "warn_linear"))
  direct <- match_by_sample(params, direct)

  for (col in intersect(names(params), names(direct))) {
    if (is.numeric(params[[col]])) {
      expect_equal(params[[col]], direct[[col]], tolerance = 1e-8, info = col)
    }
  }
})

test_that("gs_parameters fractions agree with gs_fractions_wide", {
  gs <- read_summary_consistency_gsd()

  params <- suppressWarnings(gs_parameters(
    gs,
    parameters = "fractions",
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))
  direct <- suppressWarnings(gs_fractions_wide(gs, scheme = "gradistat", extrapolate = "warn_linear"))
  direct <- match_by_sample(params, direct)

  for (col in intersect(names(params), names(direct))) {
    if (is.numeric(params[[col]])) {
      expect_equal(params[[col]], direct[[col]], tolerance = 1e-8, info = col)
    }
  }
})

test_that("gs_parameters D-spread values agree with gs_d_spread", {
  gs <- read_summary_consistency_gsd()

  params <- suppressWarnings(gs_parameters(gs, parameters = "d_spread", extrapolate = "warn_linear"))
  direct <- suppressWarnings(gs_d_spread(gs, extrapolate = "warn_linear"))
  direct <- match_by_sample(params, direct)

  for (col in intersect(names(params), names(direct))) {
    if (is.numeric(params[[col]])) {
      expect_equal(params[[col]], direct[[col]], tolerance = 1e-8, info = col)
    }
  }
})

test_that("gs_parameters mode values agree with gs_modes", {
  gs <- read_summary_consistency_gsd()

  params <- gs_parameters(gs, parameters = "modes")
  direct <- gs_modes(gs)
  mode1 <- direct[direct$mode_rank == 1, ]
  mode1 <- mode1[match(params$sample_id, mode1$sample_id), ]

  expect_equal(params$mode1_percent, mode1$mode_percent, tolerance = 1e-8)
  expect_equal(params$mode1_status, mode1$mode_status)
  expect_equal(params$sample_modality, mode1$sample_modality)
})

test_that("combined gs_parameters output has stable sample rows and names", {
  gs <- read_summary_consistency_gsd()

  params <- suppressWarnings(gs_parameters(
    gs,
    parameters = c("d_values", "d_spread", "indices", "folk_ward", "modes", "fractions"),
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))

  expect_equal(nrow(params), length(unique(gs$sample_id)))
  expect_false(any(duplicated(names(params))))
  expect_true(all(c("sample_id", "D50_um", "D90_D10_ratio", "Cu", "mean_fw_phi", "mode1_percent", "sand_percent") %in% names(params)))
})
