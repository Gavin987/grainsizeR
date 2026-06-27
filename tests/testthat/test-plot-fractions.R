test_that("plot_fractions receives closed fraction results by default", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  plot <- plot_fractions(gsd, scheme = "gradistat")

  expect_false(any(is.na(plot$data$percent)))
  expect_equal(as.numeric(rowsum(plot$data$percent, plot$data$sample_id)), c(100, 100), tolerance = 1e-8)
})

test_that("plot_fractions na_to_zero preserves closed fraction results", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  plot <- plot_fractions(gsd, scheme = "gradistat", na_to_zero = TRUE)

  expect_false(any(is.na(plot$data$percent)))
  expect_equal(as.numeric(rowsum(plot$data$percent, plot$data$sample_id)), c(100, 100), tolerance = 1e-8)
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

test_that("wentworth_detailed fraction plot closes for G2Sd-style wide input", {
  path <- tempfile(fileext = ".csv")
  values <- g2sd_style_wide()
  rownames(values) <- NULL
  wide <- data.frame(
    size = c("2000", "1000", "500", "250", "125", "63", "40", "0"),
    values,
    row.names = NULL,
    check.names = FALSE
  )
  write.csv(wide, path, row.names = FALSE)

  gsd <- read_gsd_wide(path, size_col = "size", size_unit = "auto", value_type = "percent")
  plot <- plot_fractions(gsd, scheme = "wentworth_detailed", fill_palette = "YlOrBr", na_to_zero = TRUE)

  expect_false(any(is.na(plot$data$percent)))
  expect_equal(as.numeric(rowsum(plot$data$percent, plot$data$sample_id)), c(100, 100), tolerance = 1e-8)
  expect_false("unresolved" %in% plot$data$component)
  expect_warning(ggplot2::ggplot_build(plot), NA)
})
