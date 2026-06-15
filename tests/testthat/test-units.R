test_that("linear unit conversions are reversible", {
  expect_equal(mm_to_um(c(1, 0.0625)), c(1000, 62.5))
  expect_equal(um_to_mm(c(1000, 62.5)), c(1, 0.0625))
})

test_that("phi conversions are reversible", {
  mm <- c(2, 1, 0.5, 0.0625)

  expect_equal(phi_to_mm(mm_to_phi(mm)), mm)
  expect_equal(phi_to_um(um_to_phi(mm_to_um(mm))), mm_to_um(mm))
})
