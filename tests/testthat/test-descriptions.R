test_that("description helpers classify values", {
  expect_equal(describe_mean_size_phi(2.5), "fine sand")
  expect_equal(describe_sorting_fw(1.2), "poorly sorted")
  expect_equal(describe_skewness_fw(0), "near symmetrical")
  expect_equal(describe_skewness_fw(-0.2), "coarse skewed")
  expect_equal(describe_kurtosis_fw(1.0), "mesokurtic")
})
