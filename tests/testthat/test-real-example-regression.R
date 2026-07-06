read_real_examples_for_regression <- function() {
  long_file <- system.file("extdata", "grain.long.csv", package = "grainsizeR")
  wide_file <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  if (!nzchar(long_file)) {
    long_file <- file.path("inst", "extdata", "grain.long.csv")
    wide_file <- file.path("inst", "extdata", "grain.wide.csv")
  }

  list(
    long_file = long_file,
    wide_file = wide_file,
    long = read_gsd(
      long_file,
      format = "long",
      sample_col = "sample",
      size_col = "size",
      value_col = "proportion",
      size_unit = "mm",
      value_type = "proportion"
    ),
    wide = read_gsd(
      wide_file,
      format = "wide",
      size_col = 1,
      size_unit = "mm",
      value_type = "percent"
    )
  )
}

test_that("real example files read as matching gsd_tbl objects", {
  ex <- read_real_examples_for_regression()

  expect_true(file.exists(ex$long_file))
  expect_true(file.exists(ex$wide_file))
  expect_s3_class(ex$long, "gsd_tbl")
  expect_s3_class(ex$wide, "gsd_tbl")
  expect_setequal(unique(ex$long$sample_id), unique(ex$wide$sample_id))
})

test_that("real example retained percentages sum to approximately 100", {
  ex <- read_real_examples_for_regression()

  long_totals <- tapply(ex$long$retained_percent, ex$long$sample_id, sum)
  wide_totals <- tapply(ex$wide$retained_percent, ex$wide$sample_id, sum)

  expect_equal(as.numeric(long_totals), rep(100, length(long_totals)), tolerance = 1e-6)
  expect_equal(as.numeric(wide_totals), rep(100, length(wide_totals)), tolerance = 1e-6)
})

test_that("long example has finer resolution and wide example has open fine tails", {
  ex <- read_real_examples_for_regression()
  long_bins <- table(ex$long$sample_id)
  wide_bins <- table(ex$wide$sample_id)

  expect_true(any(long_bins[names(wide_bins)] > wide_bins))
  expect_true(all(wide_bins == 7))

  final_bins <- ex$wide[ave(ex$wide$bin_id, ex$wide$sample_id, FUN = max) == ex$wide$bin_id, ]
  expect_true(all(final_bins$is_open_lower))
  expect_equal(final_bins$raw_size_um, rep(63, nrow(final_bins)))
})

test_that("coarse long and wide summaries agree for GRADISTAT-compatible gravel sand mud scheme", {
  ex <- read_real_examples_for_regression()

  finer_long <- gs_percent_finer(ex$long, sizes = 63, size_unit = "um")
  finer_wide <- gs_percent_finer(ex$wide, sizes = 63, size_unit = "um")
  idx <- match(finer_wide$sample_id, finer_long$sample_id)
  expect_equal(finer_wide$percent_finer, finer_long$percent_finer[idx], tolerance = 1e-5)

  frac_long <- gs_fractions_wide(ex$long, scheme = "gravel_sand_mud")
  frac_wide <- gs_fractions_wide(ex$wide, scheme = "gravel_sand_mud")
  idx <- match(frac_wide$sample_id, frac_long$sample_id)
  for (col in c("gravel_percent", "sand_percent", "mud_percent")) {
    expect_equal(frac_wide[[col]], frac_long[[col]][idx], tolerance = 1e-5)
  }
})

test_that("fine texture schemes require explicit extrapolation to close for long and wide example data", {
  # grain.long.csv/grain.wide.csv have no real data below 63um for any
  # sample, with nonzero pan mass, so usda/isss/uk_ssew's fine clay/silt
  # boundaries are genuinely unresolved by default (see
  # dev-notes/AUDIT_LOG.md's root-cause entry on gs_fractions()'s
  # below-boundary behavior) - `unresolved = "warn_na"` alone no longer
  # papers over this the way it silently did before the fix. The
  # sum-to-100 identity still holds once extrapolation is explicitly
  # allowed: it is a structural property of the differences telescoping,
  # independent of how numerically reliable any individual extrapolated
  # component is.
  ex <- read_real_examples_for_regression()

  for (scheme in c("usda", "isss", "uk_ssew")) {
    expect_error(
      gs_fractions(ex$long, scheme = scheme, unresolved = "warn_na"),
      "open-ended \\(pan\\) class with nonzero retained mass",
      info = scheme
    )

    long <- suppressWarnings(gs_fractions(ex$long, scheme = scheme, unresolved = "warn_na", extrapolate = "warn_linear"))
    wide <- suppressWarnings(gs_fractions(ex$wide, scheme = scheme, unresolved = "warn_na", extrapolate = "warn_linear"))
    expect_false(any(is.na(long$percent)), info = scheme)
    expect_false(any(is.na(wide$percent)), info = scheme)
    expect_equal(as.numeric(rowsum(long$percent, long$sample_id)), rep(100, length(unique(long$sample_id))), tolerance = 1e-8, info = scheme)
    expect_equal(as.numeric(rowsum(wide$percent, wide$sample_id)), rep(100, length(unique(wide$sample_id))), tolerance = 1e-8, info = scheme)
  }
})

test_that("selected real sample returns stable regression outputs", {
  ex <- read_real_examples_for_regression()
  sample_id <- "S01"
  one <- ex$long[ex$long$sample_id == sample_id, ]

  d50 <- suppressWarnings(gs_d_values(one, probs = 50, extrapolate = "warn_linear"))
  expect_true(is.finite(d50$grain_size_um))
  expect_equal(round(d50$grain_size_um, 1), 123.0)

  finer <- suppressWarnings(gs_percent_finer(
    one,
    sizes = c(60, 63),
    size_unit = "um",
    extrapolate = "warn_linear"
  ))
  expect_true(all(is.finite(finer$percent_finer)))

  fractions <- suppressWarnings(gs_fractions_wide(one, scheme = "gradistat", extrapolate = "warn_linear"))
  expect_equal(nrow(fractions), 1)

  summary <- suppressWarnings(gs_parameters(
    one,
    parameters = c("d_values", "indices", "folk_ward", "fractions"),
    fraction_scheme = "gradistat",
    extrapolate = "warn_linear"
  ))
  expect_equal(nrow(summary), 1)

  p <- suppressWarnings(plot_gradistat_summary(one, extrapolate = "warn_linear"))
  expect_s3_class(p, "ggplot")
})

test_that("dry-sieve example consistently requires extrapolation for both gs_percent_finer and gs_fractions", {
  # Before the gs_fractions() pan-mass fix, this same dry-sieve example
  # showed an inconsistency: gs_percent_finer() correctly refused to
  # resolve 2um (genuinely inside the open, unmeasured pan tail), while
  # gs_fractions()'s USDA clay/silt split silently returned 0 percent for
  # the identical, equally-unresolved boundary (see
  # dev-notes/AUDIT_LOG.md's root-cause entry). Both now agree: neither
  # resolves this threshold without the user explicitly opting into
  # extrapolation via extrapolate = "warn_linear".
  ex <- read_real_examples_for_regression()

  expect_error(
    gs_percent_finer(ex$wide, sizes = 2, size_unit = "um", extrapolate = "error"),
    "fall outside"
  )
  expect_error(
    gs_fractions(ex$wide, scheme = "usda", unresolved = "warn_na"),
    "open-ended \\(pan\\) class with nonzero retained mass"
  )

  wide_usda <- suppressWarnings(gs_fractions(ex$wide, scheme = "usda", unresolved = "warn_na", extrapolate = "warn_linear"))
  expect_false(any(is.na(wide_usda$percent)))
  expect_equal(as.numeric(rowsum(wide_usda$percent, wide_usda$sample_id)), rep(100, length(unique(wide_usda$sample_id))), tolerance = 1e-8)
})
