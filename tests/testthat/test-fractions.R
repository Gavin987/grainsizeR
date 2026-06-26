test_that("gs_fraction_schemes lists built-in schemes and components", {
  schemes <- gs_fraction_schemes()

  expect_true(all(c(
    "wentworth_major",
    "gradistat",
    "usda_tt",
    "isss",
    "uk_ssew",
    "hypres",
    "germany_63",
    "australia_20",
    "sweden_60"
  ) %in% schemes$scheme))
  expect_equal(
    schemes$component[schemes$scheme == "wentworth_major"],
    c("gravel", "sand", "mud")
  )
  expect_equal(
    schemes$component[schemes$scheme == "gradistat"],
    c("gravel", "sand", "silt", "clay", "mud")
  )

  soil_schemes <- c("usda_tt", "isss", "uk_ssew", "hypres", "germany_63", "australia_20", "sweden_60")
  for (scheme in soil_schemes) {
    expect_equal(
      schemes$component[schemes$scheme == scheme],
      c("gravel", "sand", "silt", "clay")
    )
  }
})

test_that("gs_fraction_schemes includes new source-aware boundary schemes", {
  schemes <- gs_fraction_schemes()

  hypres <- schemes[schemes$scheme == "hypres", ]
  expect_equal(hypres$lower_um, c(2000, 50, 2, 0))
  expect_equal(hypres$upper_um, c(Inf, 2000, 50, 2))

  germany <- schemes[schemes$scheme == "germany_63", ]
  expect_equal(germany$lower_um, c(2000, 63, 2, 0))
  expect_equal(germany$upper_um, c(Inf, 2000, 63, 2))

  australia <- schemes[schemes$scheme == "australia_20", ]
  expect_equal(australia$lower_um, c(2000, 20, 2, 0))
  expect_equal(australia$upper_um, c(Inf, 2000, 20, 2))

  sweden <- schemes[schemes$scheme == "sweden_60", ]
  expect_equal(sweden$lower_um, c(2000, 60, 2, 0))
  expect_equal(sweden$upper_um, c(Inf, 2000, 60, 2))
})

test_that("gs_fractions calculates Wentworth major whole-sample percentages", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_fractions(gsd, scheme = "wentworth_major")
  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  expect_equal(wn1$percent[wn1$component == "gravel"], 2.3552612, tolerance = 1e-7)
  expect_equal(wn1$percent[wn1$component == "sand"], 92.0635511, tolerance = 1e-7)
  expect_equal(wn1$percent[wn1$component == "mud"], 5.5811877, tolerance = 1e-7)

  expect_equal(wn2$percent[wn2$component == "gravel"], 0.6241215, tolerance = 1e-7)
  expect_equal(wn2$percent[wn2$component == "sand"], 84.9985943, tolerance = 1e-7)
  expect_equal(wn2$percent[wn2$component == "mud"], 14.3772842, tolerance = 1e-7)
  expect_true(all(result$resolved))
})

test_that("gs_fractions returns NA for unresolved GRADISTAT components", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    result <- gs_fractions(gsd, scheme = "gradistat", unresolved = "warn_na"),
    "could not be resolved"
  )

  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  expect_true(is.na(wn1$percent[wn1$component == "clay"]))
  expect_true(is.na(wn1$percent[wn1$component == "silt"]))
  expect_false(is.na(wn1$percent[wn1$component == "gravel"]))
  expect_false(is.na(wn1$percent[wn1$component == "sand"]))

  expect_false(is.na(wn2$percent[wn2$component == "gravel"]))
  expect_false(is.na(wn2$percent[wn2$component == "sand"]))
  expect_false(is.na(wn2$percent[wn2$component == "mud"]))
  expect_true(is.na(wn2$percent[wn2$component == "silt"]))
  expect_true(is.na(wn2$percent[wn2$component == "clay"]))
})

test_that("gs_fractions errors for unresolved components when requested", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_fractions(gsd, scheme = "gradistat", unresolved = "error"),
    "could not be resolved"
  )
})

test_that("gs_fractions can normalize fine-earth fractions", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_fractions(gsd, scheme = "wentworth_major", normalize = "fine_earth")

  expect_false("gravel" %in% result$component)
  totals <- rowsum(result$percent, result$sample_id, reorder = FALSE)
  expect_equal(as.numeric(totals), c(100, 100), tolerance = 1e-8)
})

test_that("gs_fractions_wide returns component percent columns", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_fractions_wide(gsd, scheme = "wentworth_major")

  expect_equal(nrow(result), 2)
  expect_true(all(c("gravel_percent", "sand_percent", "mud_percent") %in% names(result)))
})

test_that("gs_fractions supports new schemes on real example data", {
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

  usda <- suppressWarnings(gs_fractions(gsd, scheme = "usda_tt"))
  hypres <- suppressWarnings(gs_fractions(gsd, scheme = "hypres"))
  expect_equal(hypres$component, usda$component)
  expect_equal(hypres$lower_um, usda$lower_um)
  expect_equal(hypres$upper_um, usda$upper_um)
  expect_equal(hypres$percent, usda$percent, tolerance = 1e-8)

  isss <- suppressWarnings(gs_fractions(gsd, scheme = "isss"))
  australia <- suppressWarnings(gs_fractions(gsd, scheme = "australia_20"))
  expect_equal(australia$component, isss$component)
  expect_equal(australia$lower_um, isss$lower_um)
  expect_equal(australia$upper_um, isss$upper_um)
  expect_equal(australia$percent, isss$percent, tolerance = 1e-8)

  expect_warning(germany <- gs_fractions(gsd, scheme = "germany_63"), "could not be resolved")
  expect_warning(sweden <- gs_fractions(gsd, scheme = "sweden_60"), "could not be resolved")
  expect_s3_class(germany, "tbl_df")
  expect_s3_class(sweden, "tbl_df")
  expect_true(all(c("gravel", "sand", "silt", "clay") %in% germany$component))
  expect_true(all(c("gravel", "sand", "silt", "clay") %in% sweden$component))
})
