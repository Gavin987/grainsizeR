test_that("gs_fraction_schemes lists built-in schemes and components", {
  schemes <- gs_fraction_schemes()

  expect_true(all(c(
    "wentworth_major",
    "gravel_sand_mud",
    "wentworth_detailed",
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
  expect_true(all(c("lower_mm", "upper_mm", "lower_um", "upper_um") %in% names(schemes)))
  expect_equal(
    schemes$lower_mm[schemes$scheme == "wentworth_major"],
    c(2, 0.0625, 0)
  )
  expect_equal(
    schemes$component[schemes$scheme == "gravel_sand_mud"],
    c("gravel", "sand", "mud")
  )
  expect_equal(
    schemes$component[schemes$scheme == "gradistat"],
    c("gravel", "sand", "silt", "clay")
  )
  expect_equal(
    schemes$component[schemes$scheme == "wentworth_detailed"],
    c(
      "coarse_gravel",
      "medium_gravel",
      "fine_gravel",
      "very_fine_gravel",
      "very_coarse_sand",
      "coarse_sand",
      "medium_sand",
      "fine_sand",
      "very_fine_sand",
      "very_coarse_silt",
      "coarse_silt",
      "medium_silt",
      "fine_silt",
      "very_fine_silt",
      "clay"
    )
  )

  soil_schemes <- c("usda_tt", "isss", "uk_ssew", "hypres", "germany_63", "australia_20", "sweden_60")
  for (scheme in soil_schemes) {
    expect_equal(
      schemes$component[schemes$scheme == scheme],
      c("gravel", "sand", "silt", "clay")
    )
  }
})

test_that("gravel_sand_mud is an explicit alias of wentworth_major", {
  schemes <- gs_fraction_schemes()
  wentworth <- schemes[schemes$scheme == "wentworth_major", ]
  gsm <- schemes[schemes$scheme == "gravel_sand_mud", ]

  expect_equal(gsm$component, wentworth$component)
  expect_equal(gsm$lower_um, wentworth$lower_um)
  expect_equal(gsm$upper_um, wentworth$upper_um)
  expect_equal(gsm$lower_mm, wentworth$lower_mm)
  expect_equal(gsm$upper_mm, wentworth$upper_mm)
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

test_that("gs_fractions returns zero for absent GRADISTAT components", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_fractions(gsd, scheme = "gradistat", unresolved = "warn_na")

  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  expect_equal(wn1$percent[wn1$component == "clay"], 0)
  expect_false(is.na(wn1$percent[wn1$component == "silt"]))
  expect_false(is.na(wn1$percent[wn1$component == "gravel"]))
  expect_false(is.na(wn1$percent[wn1$component == "sand"]))

  expect_false(is.na(wn2$percent[wn2$component == "gravel"]))
  expect_false(is.na(wn2$percent[wn2$component == "sand"]))
  expect_false(is.na(wn2$percent[wn2$component == "silt"]))
  expect_equal(wn2$percent[wn2$component == "clay"], 0)

  totals <- rowsum(result$percent, result$sample_id, reorder = FALSE)
  expect_equal(as.numeric(totals), c(100, 100), tolerance = 1e-8)
})

test_that("unresolved error mode does not fail for absent outer classes", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_s3_class(gs_fractions(gsd, scheme = "gradistat", unresolved = "error"), "tbl_df")
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

test_that("gs_fractions rejects invalid schemes clearly", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_fractions(gsd, scheme = "not_a_scheme"),
    "`scheme` must be one of"
  )
})

test_that("gs_fractions rejects fine-earth normalization without a gravel component", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_fractions(gsd, scheme = "wentworth_detailed", normalize = "fine_earth"),
    "requires a fraction scheme with a `gravel` component",
    fixed = TRUE
  )
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

  germany <- gs_fractions(gsd, scheme = "germany_63")
  sweden <- gs_fractions(gsd, scheme = "sweden_60")
  expect_s3_class(germany, "tbl_df")
  expect_s3_class(sweden, "tbl_df")
  expect_true(all(c("gravel", "sand", "silt", "clay") %in% germany$component))
  expect_true(all(c("gravel", "sand", "silt", "clay") %in% sweden$component))
})

test_that("gs_fractions uses normalized units for G2Sd-style micrometre input", {
  long_um <- g2sd_wide_to_long(g2sd_style_wide())
  long_mm <- g2sd_wide_to_long(g2sd_style_wide(c("2", "1", "0.5", "0.25", "0.125", "0.063", "0.04", "0")))

  gsd_um <- as_gsd_tbl(long_um, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")
  gsd_mm <- as_gsd_tbl(long_mm, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")

  for (scheme in c("gravel_sand_mud", "wentworth_major", "wentworth_detailed", "gradistat", "usda_tt", "isss", "uk_ssew")) {
    um_fractions <- suppressWarnings(gs_fractions(gsd_um, scheme = scheme))
    mm_fractions <- suppressWarnings(gs_fractions(gsd_mm, scheme = scheme))

    expect_equal(um_fractions$component, mm_fractions$component)
    expect_equal(um_fractions$lower_mm, mm_fractions$lower_mm)
    expect_equal(um_fractions$upper_mm, mm_fractions$upper_mm)
    expect_equal(um_fractions$percent, mm_fractions$percent, tolerance = 1e-8)
  }

  gsm <- gs_fractions(gsd_um, scheme = "gravel_sand_mud")
  expect_equal(gsm$percent[gsm$sample_id == "Q1" & gsm$component == "gravel"], 5)
})

test_that("wentworth_detailed fractions close on auto-detected G2Sd-style micrometre input", {
  long_um <- g2sd_wide_to_long(g2sd_style_wide())
  gsd <- as_gsd_tbl(long_um, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")

  detailed <- gs_fractions(gsd, scheme = "wentworth_detailed")

  expect_s3_class(detailed, "tbl_df")
  expect_true(any(detailed$sample_id == "Q1"))
  expect_false(any(is.na(detailed$percent)))
  expect_equal(
    detailed$percent[detailed$sample_id == "Q1" & detailed$component == "coarse_gravel"],
    0
  )
  expect_equal(
    as.numeric(rowsum(detailed$percent, detailed$sample_id, reorder = FALSE)),
    c(100, 100),
    tolerance = 1e-8
  )
})

test_that("fraction schemes are complete non-overlapping partitions", {
  schemes <- gs_fraction_schemes()

  for (scheme in unique(schemes$scheme)) {
    one <- schemes[schemes$scheme == scheme, ]
    one <- one[order(one$order), ]

    expect_equal(one$lower_mm[nrow(one)], 0, info = scheme)
    expect_true(is.infinite(one$upper_mm[1]), info = scheme)
    expect_false(any(duplicated(one$component)), info = scheme)
    expect_equal(one$lower_mm[-nrow(one)], one$upper_mm[-1], tolerance = 1e-12, info = scheme)
  }
})

test_that("all fraction schemes close to 100 on a spanning synthetic sample", {
  x <- data.frame(
    sample_id = "A",
    size_mm = c(32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.063, 0.03125, 0.015625, 0.0078125, 0.00390625, 0.002, 0.001),
    retained = c(1, 2, 3, 4, 5, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 12)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  for (scheme in unique(gs_fraction_schemes()$scheme)) {
    result <- gs_fractions(gsd, scheme = scheme)
    expect_equal(nrow(result), sum(gs_fraction_schemes()$scheme == scheme), info = scheme)
    expect_false(any(is.na(result$percent)), info = scheme)
    expect_equal(sum(result$percent), 100, tolerance = 1e-8, info = scheme)
    expect_false(any(duplicated(result$component)), info = scheme)
  }
})
