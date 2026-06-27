test_that("plot_fractions preserves unresolved NA values by default", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    plot <- plot_fractions(gsd, scheme = "gradistat"),
    "could not be resolved"
  )

  expect_true(any(is.na(plot$data$percent)))
})

test_that("plot_fractions can plot unresolved fractions as zero", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_warning(
    plot <- plot_fractions(gsd, scheme = "gradistat", na_to_zero = TRUE),
    "could not be resolved"
  )

  expect_false(any(is.na(plot$data$percent)))
  expect_true(any(plot$data$percent == 0))
  expect_warning(ggplot2::ggplot_build(plot), NA)
})

test_that("plot_fractions validates na_to_zero", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    plot_fractions(gsd, scheme = "wentworth_major", na_to_zero = NA),
    "`na_to_zero` must be `TRUE` or `FALSE`"
  )
})
