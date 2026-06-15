test_that("gs_engineering calculates default phi-scale engineering indices", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- gs_engineering(gsd)
  wn1 <- result[result$sample_id == "WN1", ]
  wn2 <- result[result$sample_id == "WN2", ]

  expect_named(result, c(
    "sample_id",
    "D10_um",
    "D25_um",
    "D30_um",
    "D50_um",
    "D60_um",
    "D75_um",
    "Cu",
    "Cc",
    "So_trask",
    "Sk_trask",
    "fine_content_percent",
    "fine_threshold_um",
    "fine_equivalent",
    "interpolation_scale"
  ))

  expect_equal(wn1$Cu, 3.1203, tolerance = 0.0001)
  expect_equal(wn1$Cc, 0.6697, tolerance = 0.0001)
  expect_equal(wn1$So_trask, 1.9115, tolerance = 0.0001)
  expect_equal(wn1$Sk_trask, 1.2203, tolerance = 0.0001)
  expect_equal(wn1$fine_content_percent, 5.5811877, tolerance = 1e-7)
  expect_equal(wn1$fine_equivalent, 9.9179, tolerance = 0.0001)

  expect_equal(wn2$Cu, 3.8652, tolerance = 0.0001)
  expect_equal(wn2$Cc, 1.0918, tolerance = 0.0001)
  expect_equal(wn2$So_trask, 1.7458, tolerance = 0.0001)
  expect_equal(wn2$Sk_trask, 1.1791, tolerance = 0.0001)
  expect_equal(wn2$fine_content_percent, 14.3772842, tolerance = 1e-7)
  expect_equal(wn2$fine_equivalent, 29.7069, tolerance = 0.0001)
})
