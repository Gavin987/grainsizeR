test_that("gs_fraction_schemes lists built-in schemes and components", {
  schemes <- gs_fraction_schemes()

  expect_true(all(c(
    "wentworth_major",
    "gravel_sand_mud",
    "wentworth_detailed",
    "gradistat",
    "usda",
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
    schemes$lower_mm[schemes$scheme == "gravel_sand_mud"],
    c(2, 0.063, 0)
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

  soil_schemes <- c("usda", "isss", "uk_ssew", "hypres", "germany_63", "australia_20", "sweden_60")
  for (scheme in soil_schemes) {
    expect_equal(
      schemes$component[schemes$scheme == scheme],
      c("gravel", "sand", "silt", "clay")
    )
  }
})

test_that("gravel_sand_mud is independent from strict Wentworth major", {
  schemes <- gs_fraction_schemes()
  wentworth <- schemes[schemes$scheme == "wentworth_major", ]
  gsm <- schemes[schemes$scheme == "gravel_sand_mud", ]

  expect_equal(gsm$component, wentworth$component)
  expect_equal(wentworth$lower_um, c(2000, 62.5, 0))
  expect_equal(wentworth$upper_um, c(Inf, 2000, 62.5))
  expect_equal(gsm$lower_um, c(2000, 63, 0))
  expect_equal(gsm$upper_um, c(Inf, 2000, 63))
})

test_that("gravel_sand_mud uses the GRADISTAT-compatible 63 um mud boundary", {
  x <- data.frame(
    sample_id = "boundary",
    size_mm = c(2, 0.063, 0.0625, 0.004, 0.001),
    retained = c(5, 45, 10, 20, 20)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  gsm <- gs_fractions_wide(gsd, scheme = "gravel_sand_mud")
  gradistat <- gs_fractions_wide(gsd, scheme = "gradistat")
  wentworth <- gs_fractions_wide(gsd, scheme = "wentworth_major")
  # extrapolate = "warn_linear": this fixture has nonzero pan mass and
  # wentworth_detailed's finest rungs (3.90625um, 2um) fall below this
  # sample's finite range; only boundary metadata (lower_um/upper_um) is
  # checked below, not resolved percentages, so extrapolation is fine here.
  detailed <- suppressWarnings(gs_fractions(gsd, scheme = "wentworth_detailed", extrapolate = "warn_linear"))

  expect_equal(gsm$mud_percent, gradistat$silt_percent + gradistat$clay_percent, tolerance = 1e-10)
  expect_gt(abs(wentworth$mud_percent - gsm$mud_percent), 0)
  expect_equal(
    detailed$lower_um[detailed$component == "very_fine_sand"],
    62.5
  )
  expect_equal(
    detailed$upper_um[detailed$component == "very_coarse_silt"],
    62.5
  )
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

test_that("gs_fractions requires explicit extrapolation for GRADISTAT's clay boundary on tail-limited samples", {
  # WN1/WN2 (helper-ragged.R) have real, nonzero pan mass below their
  # finest measured boundaries (62.5um and 13.33um respectively), and
  # GRADISTAT's clay boundary (4um) falls below both, with no nominal-
  # equivalence match. Under the default extrapolate = "error" this must
  # not silently resolve to 0 percent (the pre-fix behavior - see
  # dev-notes/AUDIT_LOG.md's "Root-cause: gs_fractions()
  # below-finest-boundary behavior" entry) - it must error, and only
  # resolve, as a genuinely extrapolated non-zero value, when the user
  # explicitly opts in via extrapolate = "warn_linear".
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_fractions(gsd, scheme = "gradistat", unresolved = "warn_na"),
    "open-ended \\(pan\\) class with nonzero retained mass"
  )

  result <- suppressWarnings(
    gs_fractions(gsd, scheme = "gradistat", unresolved = "warn_na", extrapolate = "warn_linear")
  )
  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  # Not asserting a sign or range on the extrapolated clay value: linear
  # extrapolation across a large gap (4um requested, 62.5um/13.33um the
  # nearest real data) is a known, pre-existing hazard of
  # extrapolate = "warn_linear" generally (unrelated to this fix - the
  # same hazard exists calling gs_percent_finer()/gs_d_values() directly)
  # and can legitimately fall outside 0-100 percent. The point here is
  # only that it now resolves to a real, finite, non-hard-coded number
  # instead of the old silent exact 0.
  expect_true(is.finite(wn1$percent[wn1$component == "clay"]))
  expect_false(is.na(wn1$percent[wn1$component == "silt"]))
  expect_false(is.na(wn1$percent[wn1$component == "gravel"]))
  expect_false(is.na(wn1$percent[wn1$component == "sand"]))

  expect_true(is.finite(wn2$percent[wn2$component == "clay"]))
  expect_false(is.na(wn2$percent[wn2$component == "gravel"]))
  expect_false(is.na(wn2$percent[wn2$component == "sand"]))
  expect_false(is.na(wn2$percent[wn2$component == "silt"]))

  totals <- rowsum(result$percent, result$sample_id, reorder = FALSE)
  expect_equal(as.numeric(totals), c(100, 100), tolerance = 1e-8)
})

test_that("unresolved error mode succeeds once extrapolation is explicitly allowed", {
  # `unresolved` and `extrapolate` are orthogonal: WN1/WN2's below-boundary
  # clay component now requires explicit extrapolation (see above), which
  # `unresolved = "error"` alone does not grant - both must be set for this
  # tail-limited fixture to resolve successfully.
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_s3_class(
    suppressWarnings(gs_fractions(gsd, scheme = "gradistat", unresolved = "error", extrapolate = "warn_linear")),
    "tbl_df"
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

test_that("gs_fractions rejects pre-release USDA texture triangle scheme name", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    gs_fractions(gsd, scheme = "usda_tt"),
    'scheme = "usda_tt"',
    fixed = TRUE
  )
  expect_error(
    gs_fractions_wide(gsd, scheme = "usda_tt"),
    'scheme = "usda_tt"',
    fixed = TRUE
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

  # extrapolate = "warn_linear": some samples in this real example dataset
  # have nonzero pan mass below these schemes' fine boundaries (see
  # test-fractions.R's dedicated pan-mass tests for resolution-correctness
  # coverage) - this test is about cross-scheme consistency, not tail
  # resolution.
  usda <- suppressWarnings(gs_fractions(gsd, scheme = "usda", extrapolate = "warn_linear"))
  hypres <- suppressWarnings(gs_fractions(gsd, scheme = "hypres", extrapolate = "warn_linear"))
  expect_equal(hypres$component, usda$component)
  expect_equal(hypres$lower_um, usda$lower_um)
  expect_equal(hypres$upper_um, usda$upper_um)
  expect_equal(hypres$percent, usda$percent, tolerance = 1e-8)

  isss <- suppressWarnings(gs_fractions(gsd, scheme = "isss", extrapolate = "warn_linear"))
  australia <- suppressWarnings(gs_fractions(gsd, scheme = "australia_20", extrapolate = "warn_linear"))
  expect_equal(australia$component, isss$component)
  expect_equal(australia$lower_um, isss$lower_um)
  expect_equal(australia$upper_um, isss$upper_um)
  expect_equal(australia$percent, isss$percent, tolerance = 1e-8)

  germany <- suppressWarnings(gs_fractions(gsd, scheme = "germany_63", extrapolate = "warn_linear"))
  sweden <- suppressWarnings(gs_fractions(gsd, scheme = "sweden_60", extrapolate = "warn_linear"))
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

  for (scheme in c("gravel_sand_mud", "wentworth_major", "wentworth_detailed", "gradistat", "usda", "isss", "uk_ssew")) {
    # extrapolate = "warn_linear": this fixture's samples have nonzero pan
    # mass below some schemes' fine boundaries - this test is about
    # um-vs-mm unit-normalization consistency, not tail resolution.
    um_fractions <- suppressWarnings(gs_fractions(gsd_um, scheme = scheme, extrapolate = "warn_linear"))
    mm_fractions <- suppressWarnings(gs_fractions(gsd_mm, scheme = scheme, extrapolate = "warn_linear"))

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

  # extrapolate = "warn_linear": this fixture has nonzero pan mass below
  # wentworth_detailed's finest rungs - this test is about the schemes'
  # fractions closing to 100 percent, not tail-resolution correctness.
  detailed <- suppressWarnings(gs_fractions(gsd, scheme = "wentworth_detailed", extrapolate = "warn_linear"))

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

test_that("gravel_sand_mud and wentworth_major resolve identically on sieve-only samples via nominal equivalence", {
  # Finest measured (finite) boundary is exactly 63 um, with nonzero pan
  # mass below it. gravel_sand_mud's 63 um threshold is an exact boundary
  # match; wentworth_major's 62.5 um threshold has no measured data of its
  # own but is a recognized nominal-equivalence match for the same real
  # 63 um boundary, so both schemes must read off the identical value -
  # not the old hard-coded 0 percent.
  x <- data.frame(
    sample_id = "sieve_only",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
    retained = c(0, 0, 0.223, 13.0, 76.2, 9.92, 0.657)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  gsm <- gs_fractions_wide(gsd, scheme = "gravel_sand_mud", extrapolate = "error")
  wentworth <- gs_fractions_wide(gsd, scheme = "wentworth_major", extrapolate = "error")

  expect_equal(gsm$mud_percent, 0.657, tolerance = 1e-8)
  expect_equal(wentworth$mud_percent, gsm$mud_percent, tolerance = 1e-8)
})

test_that("nominal equivalence does not override real interpolation for samples with finer-resolution data", {
  # Both 63 um and finer boundaries (20 um, 2 um) are genuinely measured
  # here, so wentworth_major's 62.5 um threshold is resolvable by real
  # interpolation and must differ from gravel_sand_mud's exact 63 um
  # value, not be silently equivalenced to it.
  x <- data.frame(
    sample_id = "augmented",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.02, 0.002, 0.001),
    retained = c(0, 0, 0.2, 10, 60, 15, 8, 5, 1.8)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  gsm <- gs_fractions_wide(gsd, scheme = "gravel_sand_mud", extrapolate = "error")
  wentworth <- gs_fractions_wide(gsd, scheme = "wentworth_major", extrapolate = "error")

  expect_gt(abs(wentworth$mud_percent - gsm$mud_percent), 0)
})

test_that("gs_fractions errors by default on a genuinely unresolved below-boundary threshold with nonzero pan mass", {
  # USDA's 50 um threshold is not in any equivalence group; on this
  # sieve-only sample (finest boundary 63 um, pan mass 0.657) it is
  # genuinely unresolvable, and must error under the default
  # extrapolate = "error" rather than silently returning 0 percent (the
  # pre-fix behavior - see dev-notes/AUDIT_LOG.md's root-cause entry).
  x <- data.frame(
    sample_id = "sieve_only",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
    retained = c(0, 0, 0.223, 13.0, 76.2, 9.92, 0.657)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  expect_error(
    gs_fractions_wide(gsd, scheme = "usda", extrapolate = "error"),
    "open-ended \\(pan\\) class with nonzero retained mass"
  )
})

test_that("gs_fractions extrapolates with a warning (not a silent 0) when the user opts in via warn_linear", {
  x <- data.frame(
    sample_id = "sieve_only",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
    retained = c(0, 0, 0.223, 13.0, 76.2, 9.92, 0.657)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  expect_warning(
    result <- gs_fractions_wide(gsd, scheme = "usda", extrapolate = "warn_linear"),
    "linearly extrapolating"
  )
  expect_false(result$silt_percent == 0)
})

test_that("gs_fractions still resolves a genuine zero below the finite boundary when the pan is empty", {
  # No assumption is required here: the pan's retained mass is exactly
  # zero, so 0 percent finer than any threshold below the finite range is
  # exactly correct, not a guess - this must be unaffected by the fix.
  x <- data.frame(
    sample_id = "zero_pan",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
    retained = c(0, 0, 0.223, 13.0, 76.777, 10, 0)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")

  result <- gs_fractions_wide(gsd, scheme = "usda", extrapolate = "error")

  expect_equal(result$silt_percent, 0)
  expect_equal(result$clay_percent, 0)
})

test_that("percent_finer_lookup batches per-sample thresholds identically to one-at-a-time lookups", {
  # Multiple samples with different finite ranges, and thresholds that fall
  # below, above, and inside each sample's observed range, so the batched
  # in-range gs_percent_finer() call and the below/above shortcuts are all
  # exercised together across more than one sample. The finest listed size
  # becomes the open-lower (pan) row automatically; its retained mass is
  # kept at exactly 0 here so the below-range threshold below resolves to
  # a legitimate, assumption-free 0 percent (this test is about batching
  # consistency, not pan-mass semantics - see the dedicated pan-mass tests
  # above for that).
  x <- data.frame(
    sample_id = rep(c("wide_range", "narrow_range"), each = 5),
    size_mm = rep(c(2000, 62.5, 2, 0.063, 0.002), 2),
    retained = c(5, 20, 30, 45, 0, 10, 40, 30, 20, 0)
  )
  gsd <- as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")
  normalized <- .gsd_tbl_with_normalized_mm_sizes(gsd)

  # Chosen relative to this sample's actual finite boundary range (roughly
  # 0.000063-2 mm after normalization): comfortably below, inside, and above.
  thresholds_mm <- sort(unique(c(0.00001, 0.0005, 0.001, 1, 3000)))

  batched <- percent_finer_lookup(
    gsd,
    thresholds_mm = thresholds_mm,
    interpolation_scale = "phi",
    extrapolate = "error",
    unresolved = "warn_na"
  )

  reference_rows <- list()
  row_id <- 1
  for (sample_id in unique(as.character(gsd$sample_id))) {
    sample_x <- normalized[normalized$sample_id == sample_id, ]
    curve <- gs_cumulative(sample_x)
    min_mm <- min(curve$boundary_mm)
    max_mm <- max(curve$boundary_mm)
    for (threshold in thresholds_mm) {
      if (threshold < min_mm) {
        reference_rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id, threshold_mm = threshold, threshold_um = mm_to_um(threshold),
          percent_finer = 0, resolved = TRUE
        )
      } else if (threshold > max_mm) {
        reference_rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id, threshold_mm = threshold, threshold_um = mm_to_um(threshold),
          percent_finer = 100, resolved = TRUE
        )
      } else {
        one <- gs_percent_finer(sample_x, sizes = threshold, size_unit = "mm", interpolation_scale = "phi", extrapolate = "error")
        reference_rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id, threshold_mm = one$threshold_mm, threshold_um = one$threshold_um,
          percent_finer = one$percent_finer, resolved = TRUE
        )
      }
      row_id <- row_id + 1
    }
  }
  reference <- do.call(rbind, reference_rows)
  rownames(reference) <- NULL

  # At least one below-range, one above-range, and one in-range threshold per
  # sample must actually be exercised for this to be a meaningful check.
  expect_true(any(reference$percent_finer == 0))
  expect_true(any(reference$percent_finer == 100))
  expect_true(any(reference$percent_finer > 0 & reference$percent_finer < 100))

  expect_equal(
    as.data.frame(batched[order(batched$sample_id, batched$threshold_mm), ]),
    as.data.frame(reference[order(reference$sample_id, reference$threshold_mm), ]),
    ignore_attr = TRUE
  )
})
