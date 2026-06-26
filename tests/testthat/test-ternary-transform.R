test_that("ternary_to_xy maps triangle vertices", {
  left <- ternary_to_xy(100, 0, 0)
  right <- ternary_to_xy(0, 100, 0)
  top <- ternary_to_xy(0, 0, 100)

  expect_equal(left$x, 0)
  expect_equal(left$y, 0)
  expect_equal(right$x, 1)
  expect_equal(right$y, 0)
  expect_equal(top$x, 0.5)
  expect_equal(top$y, sqrt(3) / 2)
})

test_that("ternary_to_xy normalizes rows", {
  result <- ternary_to_xy(left = 1, right = 1, top = 2)

  expect_equal(result$left, 25)
  expect_equal(result$right, 25)
  expect_equal(result$top, 50)
  expect_equal(result$x, 0.5)
  expect_equal(result$y, sqrt(3) / 4)
})
