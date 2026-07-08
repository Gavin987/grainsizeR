test_that("gs_parameters returns requested D-values in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(gsd, parameters = c("D10", "D30", "D50"))

  expect_named(result, c("sample_id", "D10_um", "D30_um", "D50_um"))
  expect_equal(nrow(result), 2)
  expect_true(all(c("WN1", "WN2") %in% result$sample_id))
})

test_that("gs_parameters combines D-values and grain-size indices", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(gsd, parameters = c("D10", "D30", "indices"))

  expect_true(all(c("D10_um", "D30_um", "Cu", "Cc", "fine_content_percent") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters keeps engineering as a compatibility alias", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  preferred <- gs_parameters(gsd, parameters = c("D10", "indices"))
  compatible <- gs_parameters(gsd, parameters = c("D10", "engineering"))

  expect_equal(preferred, compatible)
})

test_that("gs_parameters supports long output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(
    gsd,
    parameters = c("D10", "D30", "indices"),
    output = "long"
  )

  expect_named(result, c("sample_id", "parameter", "value", "unit", "method"))
  expect_true(all(c("D10_um", "D30_um", "Cu", "fine_content_percent") %in% result$parameter))
})

test_that("gs_parameters rejects unknown parameters", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_parameters(gsd, parameters = c("D10", "not_a_parameter")),
    "Unsupported parameters"
  )
})

test_that("gs_parameters includes Folk and Ward columns in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  result <- gs_parameters(wn2, parameters = "folk_ward")

  expect_true(all(c("mean_fw_phi", "sorting_fw_phi", "skewness_fw", "kurtosis_fw") %in% names(result)))
  expect_true(all(c("mean_size_class", "sorting_class", "skewness_class", "kurtosis_class") %in% names(result)))
})

test_that("gs_parameters combines D-values, indices, and Folk and Ward statistics", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = c("D10", "D50", "indices", "folk_ward"),
      extrapolate = "warn_linear"
    ),
    "linearly extrapolating"
  )

  expect_true(all(c("D10_um", "D50_um", "Cu", "mean_fw_phi", "kurtosis_fw") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters long output includes numeric Folk and Ward parameters", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  result <- gs_parameters(wn2, parameters = "folk_ward", output = "long")

  expect_named(result, c("sample_id", "parameter", "value", "unit", "method"))
  expect_true(all(c("mean_fw_phi", "sorting_fw_phi", "skewness_fw", "kurtosis_fw") %in% result$parameter))
  expect_false(any(c("mean_size_class", "sorting_class") %in% result$parameter))
  expect_true(all(result$method[result$parameter == "mean_fw_phi"] == "folk_ward"))
})

test_that("gs_parameters errors for moments by default", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_parameters(gsd, parameters = "moments"),
    "nonzero retained percent in open-ended classes"
  )
})

test_that("gs_parameters includes moments in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = "moments",
      moments_open_end = "extend_phi"
    ),
    "estimated by extending adjacent phi intervals"
  )

  expect_true(all(c(
    "mean_moment_phi",
    "mean_moment_um",
    "sd_moment_phi",
    "skewness_moment",
    "kurtosis_moment",
    "moments_open_end"
  ) %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters combines moments with other parameter families", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    expect_warning(
      result <- gs_parameters(
        gsd,
        parameters = c("D10", "D50", "indices", "folk_ward", "moments"),
        extrapolate = "warn_linear",
        moments_open_end = "extend_phi"
      ),
      "linearly extrapolating"
    ),
    "estimated by extending adjacent phi intervals"
  )

  expect_true(all(c(
    "D10_um",
    "D50_um",
    "Cu",
    "mean_fw_phi",
    "mean_moment_phi",
    "sd_moment_phi"
  ) %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters long output includes numeric moment rows", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = "moments",
      output = "long",
      moments_open_end = "extend_phi"
    ),
    "estimated by extending adjacent phi intervals"
  )

  expect_true(all(c("mean_moment_phi", "sd_moment_phi", "skewness_moment") %in% result$parameter))
  expect_true(all(result$method[result$parameter == "mean_moment_phi"] == "moments"))
  expect_true(all(result$unit[result$parameter == "sd_moment_phi"] == "phi"))
})

test_that("gs_parameters includes fractions in wide output", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(
    gsd,
    parameters = "fractions",
    fraction_scheme = "wentworth_major"
  )

  expect_true(all(c("gravel_percent", "sand_percent", "mud_percent") %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters combines fractions with other parameter families", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_parameters(
      gsd,
      parameters = c("D50", "indices", "folk_ward", "fractions"),
      extrapolate = "warn_linear",
      fraction_scheme = "wentworth_major"
    ),
    "linearly extrapolating"
  )

  expect_true(all(c(
    "D50_um",
    "Cu",
    "mean_fw_phi",
    "gravel_percent",
    "sand_percent",
    "mud_percent"
  ) %in% names(result)))
  expect_equal(nrow(result), 2)
})

test_that("gs_parameters long output includes numeric fraction rows", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_parameters(
    gsd,
    parameters = "fractions",
    output = "long",
    fraction_scheme = "wentworth_major"
  )

  expect_true(all(c("gravel_percent", "sand_percent", "mud_percent") %in% result$parameter))
  expect_true(all(result$method[result$parameter == "sand_percent"] == "fractions"))
  expect_true(all(result$unit[result$parameter == "sand_percent"] == "percent"))
})

parameters_ref_table <- function(gsd,
                                 parameters,
                                 d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
                                 interpolation_scale = "phi",
                                 extrapolate = "warn_linear",
                                 d_spread_scale = "um",
                                 fine_threshold_um = 62.5,
                                 fraction_scheme = "gravel_sand_mud",
                                 fraction_normalize = "none",
                                 fraction_unresolved = "warn_na") {
  sample_ids <- unique(as.character(gsd$sample_id))
  out <- tibble::tibble(sample_id = sample_ids)

  d_tokens <- parse_d_parameters(parameters)
  probs <- unique(c(d_tokens, if ("d_values" %in% parameters) d_values else numeric()))
  if (length(probs) > 0) {
    d <- gs_d_values(
      gsd,
      probs = probs,
      interpolation_scale = interpolation_scale,
      output_unit = "um",
      extrapolate = extrapolate
    )
    d_wide <- tibble::tibble(sample_id = sample_ids)
    for (prob in probs) {
      values <- d$grain_size_um[d$percentile == prob]
      names(values) <- d$sample_id[d$percentile == prob]
      d_wide[[paste0("D", prob, "_um")]] <- unname(values[d_wide$sample_id])
    }
    out <- .merge_new_parameter_columns(out, d_wide)
  }

  if ("d_spread" %in% parameters) {
    out <- .merge_new_parameter_columns(
      out,
      gs_d_spread(
        gsd,
        scale = d_spread_scale,
        interpolation_scale = interpolation_scale,
        extrapolate = extrapolate
      )
    )
  }

  if ("indices" %in% parameters) {
    out <- .merge_new_parameter_columns(
      out,
      gs_grain_size_indices(
        gsd,
        fine_threshold_um = fine_threshold_um,
        interpolation_scale = interpolation_scale,
        extrapolate = extrapolate
      )
    )
  }

  if ("folk_ward" %in% parameters) {
    out <- .merge_new_parameter_columns(
      out,
      gs_folk_ward(
        gsd,
        interpolation_scale = interpolation_scale,
        extrapolate = extrapolate,
        include_descriptions = TRUE
      )
    )
  }

  if ("fractions" %in% parameters) {
    out <- .merge_new_parameter_columns(
      out,
      gs_fractions_wide(
        gsd,
        scheme = fraction_scheme,
        normalize = fraction_normalize,
        interpolation_scale = interpolation_scale,
        unresolved = fraction_unresolved,
        extrapolate = extrapolate
      )
    )
  }

  tibble::as_tibble(out)
}

parameters_to_long_ref <- function(wide) {
  value_cols <- setdiff(names(wide), "sample_id")
  value_cols <- value_cols[vapply(wide[value_cols], function(x) is.numeric(x) || is.logical(x), logical(1))]
  rows <- lapply(value_cols, function(col) {
    tibble::tibble(
      sample_id = wide$sample_id,
      parameter = col,
      value = as.numeric(wide[[col]]),
      unit = parameter_unit(col),
      method = parameter_method(col)
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

parameters_edge_gsd <- function() {
  as_gsd_tbl(
    data.frame(
      sample_id = rep(c("open_tail", "zero_tie", "nominal"), each = 8),
      size_mm = rep(c(4, 2, 1, 0.5, 0.25, 0.125, 0.063, 0), 3),
      retained = c(
        5, 8, 12, 18, 20, 17, 10, 10,
        4, 0, 0, 26, 30, 20, 20, 0,
        6, 8, 10, 16, 24, 20, 16, 0
      )
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
}

test_that("gs_parameters shared cumulative path matches standalone public functions", {
  bundled_wide <- read_gsd_wide(system.file("extdata", "grain.wide.csv", package = "grainsizeR"))
  bundled_long_raw <- readr::read_csv(system.file("extdata", "grain.long.csv", package = "grainsizeR"), show_col_types = FALSE)
  bundled_long <- as_gsd_tbl(bundled_long_raw, sample, size, proportion)
  edge <- parameters_edge_gsd()

  cases <- list(
    bundled_wide = list(gsd = bundled_wide, scheme = "gravel_sand_mud"),
    bundled_long = list(gsd = bundled_long, scheme = "gravel_sand_mud"),
    edge = list(gsd = edge, scheme = "wentworth_major")
  )
  parameter_sets <- list(
    d_values = "d_values",
    fractions = "fractions",
    d_spread = "d_spread",
    indices = "indices",
    folk_ward = "folk_ward",
    mixed = c("d_values", "d_spread", "indices", "folk_ward", "fractions")
  )

  for (case in cases) {
    for (parameters in parameter_sets) {
      actual <- suppressWarnings(gs_parameters(
        case$gsd,
        parameters = parameters,
        extrapolate = "warn_linear",
        fraction_scheme = case$scheme
      ))
      expected <- suppressWarnings(parameters_ref_table(
        case$gsd,
        parameters = parameters,
        extrapolate = "warn_linear",
        fraction_scheme = case$scheme
      ))

      expect_equal(actual, expected, tolerance = 1e-8)
    }
  }

  wide_actual <- suppressWarnings(gs_parameters(
    edge,
    parameters = c("d_values", "d_spread", "indices", "folk_ward", "fractions"),
    output = "wide",
    extrapolate = "warn_linear",
    fraction_scheme = "wentworth_major"
  ))
  long_actual <- suppressWarnings(gs_parameters(
    edge,
    parameters = c("d_values", "d_spread", "indices", "folk_ward", "fractions"),
    output = "long",
    extrapolate = "warn_linear",
    fraction_scheme = "wentworth_major"
  ))

  expect_equal(long_actual, parameters_to_long_ref(wide_actual), tolerance = 1e-8)
})

test_that("standalone percentile and fraction-family functions remain independent", {
  gsd <- parameters_edge_gsd()

  expect_s3_class(suppressWarnings(gs_d_values(gsd, extrapolate = "warn_linear")), "tbl_df")
  expect_s3_class(suppressWarnings(gs_percent_finer(gsd, sizes = c(62.5, 63), extrapolate = "warn_linear")), "tbl_df")
  expect_s3_class(suppressWarnings(gs_fractions(gsd, scheme = "wentworth_major", extrapolate = "warn_linear")), "tbl_df")
  expect_s3_class(suppressWarnings(gs_d_spread(gsd, extrapolate = "warn_linear")), "tbl_df")
  expect_s3_class(suppressWarnings(gs_folk_ward(gsd, extrapolate = "warn_linear")), "tbl_df")
})
