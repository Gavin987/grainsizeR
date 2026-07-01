ragged_input <- data.frame(
  sample_id = c(
    rep("WN1", 7),
    rep("WN2", 11)
  ),
  size_mm = c(
    2, 1, 0.5, 0.25, 0.125, 0.0625, 0.001,
    2, 1, 0.5, 0.25, 0.125, 0.0625, 0.047256696,
    0.034866183, 0.022853437, 0.013330233, 0.001
  ),
  retained_proportion = c(
    0.023552612, 0.026157166, 0.046175026, 0.250818574,
    0.221275487, 0.376209257, 0.055811877,
    0.006241215, 0.009783525, 0.015799831, 0.191003655,
    0.268428451, 0.364970481, 0.02396214, 0.041933746,
    0.035943211, 0.01198107, 0.029952675
  )
)

test_that("as_gsd_tbl supports ragged long-format grain-size data", {
  gsd <- as_gsd_tbl(
    ragged_input,
    sample_id,
    size_mm,
    retained_proportion,
    measurement_method = "sieve"
  )

  expect_equal(sum(gsd$sample_id == "WN1"), 7)
  expect_equal(sum(gsd$sample_id == "WN2"), 11)
  expect_equal(unique(gsd$measurement_method), "sieve")
  expect_equal(
    as.numeric(rowsum(gsd$retained_percent, gsd$sample_id)),
    c(100, 99.999999)
  )
})

test_that("as_gsd_tbl constructs open-ended terminal classes correctly", {
  gsd <- as_gsd_tbl(ragged_input, sample_id, size_mm, retained_proportion)

  wn1 <- gsd[gsd$sample_id == "WN1", ]
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  expect_true(wn1$is_open_upper[1])
  expect_true(wn2$is_open_upper[1])
  expect_true(wn1$is_open_lower[nrow(wn1)])
  expect_true(wn2$is_open_lower[nrow(wn2)])

  expect_equal(wn1$raw_size_um[nrow(wn1)], 1)
  expect_equal(wn1$size_upper_um[nrow(wn1)], 62.5)
  expect_true(is.na(wn1$size_lower_um[nrow(wn1)]))

  expect_equal(wn2$raw_size_um[nrow(wn2)], 1)
  expect_equal(wn2$size_upper_um[nrow(wn2)], 13.330233)
  expect_true(is.na(wn2$size_lower_um[nrow(wn2)]))
})

test_that("as_gsd_tbl sorts sizes from coarse to fine within each sample", {
  shuffled <- ragged_input[c(7:1, 18:8), ]
  gsd <- as_gsd_tbl(shuffled, sample_id, size_mm, retained_proportion)

  wn1 <- gsd[gsd$sample_id == "WN1", ]
  expect_equal(wn1$raw_size_um, c(2000, 1000, 500, 250, 125, 62.5, 1))
  expect_equal(wn1$bin_id, seq_len(7))
})

test_that("weight input is normalized within sample", {
  x <- data.frame(
    sample_id = c("A", "A", "B", "B"),
    size_mm = c(1, 0.001, 1, 0.001),
    weight = c(1, 3, 2, 2)
  )

  gsd <- as_gsd_tbl(x, sample_id, size_mm, weight, value_type = "weight")
  totals <- as.numeric(rowsum(gsd$retained_percent, gsd$sample_id))

  expect_equal(totals, c(100, 100))
  expect_equal(gsd$retained_percent[gsd$sample_id == "A"], c(25, 75))
})

test_that("read_gsd reads CSV input and returns a gsd_tbl", {
  path <- tempfile(fileext = ".csv")
  write.csv(ragged_input, path, row.names = FALSE)

  gsd <- read_gsd(path, sample_id, size_mm, retained_proportion)

  expect_s3_class(gsd, "gsd_tbl")
  expect_equal(nrow(gsd), nrow(ragged_input))
})

test_that("read_gsd infers bundled long example columns", {
  path <- system.file("extdata", "grain.long.csv", package = "grainsizeR")

  gsd <- read_gsd(path)

  expect_s3_class(gsd, "gsd_tbl")
  expect_true(all(c("sample_id", "bin_id", "raw_size_um") %in% names(gsd)))
  expect_true(all(c("S01", "S02") %in% gsd$sample_id))
})

test_that("as_gsd_tbl auto-detects G2Sd-style micrometre size labels", {
  long_um <- g2sd_wide_to_long(g2sd_style_wide())
  gsd_um <- as_gsd_tbl(
    long_um,
    sample_id,
    size,
    retained_percent,
    size_unit = "auto",
    value_type = "percent"
  )

  q1 <- gsd_um[gsd_um$sample_id == "Q1", ]
  expect_equal(q1$raw_size_um, c(2000, 1000, 500, 250, 125, 63, 40, 1))
  expect_equal(um_to_mm(q1$raw_size_um[1:7]), c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.04))
  expect_equal(q1$raw_size_um[nrow(q1)], 1)
  expect_true(q1$is_open_lower[nrow(q1)])
  expect_true(is.na(q1$size_lower_um[nrow(q1)]))
})

test_that("as_gsd_tbl auto-detected micrometre input matches equivalent millimetre input", {
  long_um <- g2sd_wide_to_long(g2sd_style_wide())
  long_mm <- g2sd_wide_to_long(g2sd_style_wide(c("2", "1", "0.5", "0.25", "0.125", "0.063", "0.04", "0")))

  gsd_um <- as_gsd_tbl(long_um, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")
  gsd_mm <- as_gsd_tbl(long_mm, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")

  expect_equal(gsd_um$raw_size_um, gsd_mm$raw_size_um)
  expect_equal(gsd_um$size_lower_um, gsd_mm$size_lower_um)
  expect_equal(gsd_um$size_upper_um, gsd_mm$size_upper_um)
  expect_equal(gsd_um$retained_percent, gsd_mm$retained_percent)
})

test_that("explicit size_unit overrides auto-detection", {
  x <- data.frame(
    sample_id = c("A", "A"),
    size = c(1000, 1),
    retained_percent = c(40, 60)
  )

  as_um <- as_gsd_tbl(x, sample_id, size, retained_percent, size_unit = "um", value_type = "percent")
  as_mm <- as_gsd_tbl(x, sample_id, size, retained_percent, size_unit = "mm", value_type = "percent")
  as_auto <- as_gsd_tbl(x, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")

  expect_equal(as_um$raw_size_um, c(1000, 1))
  expect_equal(as_mm$raw_size_um, c(1000000, 1000))
  expect_equal(as_auto$raw_size_um, as_um$raw_size_um)
})

test_that("zero lower-tail rows do not affect auto unit detection", {
  x <- data.frame(
    sample_id = c("A", "A", "A"),
    size = c(2, 0.063, 0),
    retained_percent = c(20, 70, 10)
  )

  gsd <- as_gsd_tbl(x, sample_id, size, retained_percent, size_unit = "auto", value_type = "percent")

  expect_equal(gsd$raw_size_um, c(2000, 63, 1))
  expect_true(gsd$is_open_lower[nrow(gsd)])
})

test_that("internal size normalizer respects explicit size metadata", {
  size_mm <- getFromNamespace(".gsd_size_mm", "grainsizeR")

  expect_equal(size_mm(data.frame(raw_size_um = c(2000, 63, 1))), c(2, 0.063, 0.001))
  expect_equal(size_mm(data.frame(size_mm = c(2, 0.063, 0))), c(2, 0.063, 0))
  expect_equal(size_mm(data.frame(size_um = c(2000, 63, 0))), c(2, 0.063, 0))
  expect_equal(size_mm(c(2000, 1000, 0, NA, Inf)), c(2, 1, 0, NA, Inf))
  expect_equal(size_mm(c(2, 1, 0.063, 0, NA, Inf)), c(2, 1, 0.063, 0, NA, Inf))
})
