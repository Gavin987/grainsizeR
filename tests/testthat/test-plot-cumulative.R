plot_cumulative_test_gsd <- function() {
  x <- data.frame(
    sample_id = c(rep("A", 6), rep("B", 6)),
    size_mm = rep(c(2, 1, 0.5, 0.25, 0.125, 0.063), 2),
    retained_proportion = c(
      0.05, 0.10, 0.25, 0.30, 0.20, 0.10,
      0.10, 0.20, 0.25, 0.20, 0.15, 0.10
    )
  )
  as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
}

test_that("plot_cumulative requires one selected sample", {
  gsd <- plot_cumulative_test_gsd()

  expect_error(plot_cumulative(gsd), "plots one sample at a time")
  expect_s3_class(plot_cumulative(gsd, sample_id = "A"), "ggplot")
})

test_that("plot_cumulative uses millimetre log10 particle-size breaks", {
  plot <- plot_cumulative(plot_cumulative_test_gsd(), sample_id = "A")
  x_scales <- vapply(plot$scales$scales, function(scale) "x" %in% scale$aesthetics, logical(1))
  scale <- plot$scales$scales[[which(x_scales)[1]]]

  expect_equal(plot$labels$x, "Particle size (mm)")
  expect_equal(scale$limits, log10(c(0.001, 2)))
  expect_equal(scale$breaks(c(0.001, 2)), c(0.001, 0.01, 0.1, 1))
  expect_equal(scale$labels(c(0.001, 0.01, 0.1, 1)), c("0.001", "0.01", "0.1", "1"))
})

test_that("plot_cumulative can display micrometre log10 particle sizes", {
  plot <- plot_cumulative(plot_cumulative_test_gsd(), sample_id = "A", particle_unit = "um")
  x_scales <- vapply(plot$scales$scales, function(scale) "x" %in% scale$aesthetics, logical(1))
  scale <- plot$scales$scales[[which(x_scales)[1]]]

  expect_equal(plot$labels$x, "Particle size (um)")
  expect_equal(scale$limits, log10(c(1, 2000)))
  expect_equal(scale$breaks(c(1, 2000)), c(1, 10, 100, 1000))
  expect_equal(scale$labels(c(1, 10, 100, 1000)), c("1", "10", "100", "1000"))
})

test_that("plot_cumulative uses a thick black cumulative line", {
  plot <- plot_cumulative(plot_cumulative_test_gsd(), sample_id = "A")
  line_layers <- vapply(plot$layers, function(layer) inherits(layer$geom, "GeomLine"), logical(1))
  line_layer <- plot$layers[[which(line_layers)[1]]]
  line_color <- if (is.null(line_layer$aes_params$colour)) line_layer$aes_params$color else line_layer$aes_params$colour

  expect_equal(line_color, "black")
  expect_gte(line_layer$aes_params$linewidth, 1)
})
