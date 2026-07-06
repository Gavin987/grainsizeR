test_that("0.0625/0.063 mm are recognized as nominally equivalent", {
  expect_true(is_nominally_equivalent_mm(0.0625, 0.063))
  expect_true(is_nominally_equivalent_mm(0.063, 0.0625))
  expect_true(is_nominally_equivalent_mm(0.0625, 0.0625))
  expect_true(is_nominally_equivalent_mm(0.063, 0.063))
})

test_that("unrelated boundaries are never falsely equivalenced", {
  expect_false(is_nominally_equivalent_mm(0.05, 0.063))
  expect_false(is_nominally_equivalent_mm(0.05, 0.0625))
  expect_false(is_nominally_equivalent_mm(0.02, 0.063))
  expect_false(is_nominally_equivalent_mm(0.06, 0.063))
  expect_false(is_nominally_equivalent_mm(2, 0.063))
})

test_that("nominally_equivalent_boundary_mm finds the matching boundary or NA", {
  boundaries <- c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001)
  expect_equal(nominally_equivalent_boundary_mm(0.0625, boundaries), 0.063)
  expect_equal(nominally_equivalent_boundary_mm(0.063, boundaries), 0.063)
  expect_true(is.na(nominally_equivalent_boundary_mm(0.05, boundaries)))
  expect_true(is.na(nominally_equivalent_boundary_mm(0.02, boundaries)))
})

test_that("nominally_equivalent_boundary_um matches on the micrometre scale", {
  boundaries_um <- c(2000, 1000, 500, 250, 125, 63, 1)
  expect_equal(nominally_equivalent_boundary_um(62.5, boundaries_um), 63)
  expect_true(is.na(nominally_equivalent_boundary_um(50, boundaries_um)))
  expect_true(is.na(nominally_equivalent_boundary_um(20, boundaries_um)))
})
