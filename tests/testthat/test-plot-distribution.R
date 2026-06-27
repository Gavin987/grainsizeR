plot_distribution_test_gsd <- function() {
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

test_that("plot_distribution requires one selected sample", {
  gsd <- plot_distribution_test_gsd()

  expect_error(plot_distribution(gsd), "plots one sample at a time")
  expect_s3_class(plot_distribution(gsd, sample_id = "A"), "ggplot")
})

test_that("plot_distribution uses millimetre log10 particle-size breaks", {
  plot <- plot_distribution(plot_distribution_test_gsd(), sample_id = "A")
  x_scales <- vapply(plot$scales$scales, function(scale) "x" %in% scale$aesthetics, logical(1))
  scale <- plot$scales$scales[[which(x_scales)[1]]]

  expect_equal(plot$labels$x, "Particle size (mm)")
  expect_equal(scale$limits, log10(c(0.001, 10)))
  expect_equal(scale$breaks(c(0.001, 10)), c(0.001, 0.01, 0.1, 1, 10))
  expect_equal(scale$labels(c(0.001, 0.01, 0.1, 1, 10)), c("0.001", "0.01", "0.1", "1", "10"))
})

test_that("plot_distribution can display micrometre log10 particle sizes", {
  plot <- plot_distribution(plot_distribution_test_gsd(), sample_id = "A", particle_unit = "um")
  x_scales <- vapply(plot$scales$scales, function(scale) "x" %in% scale$aesthetics, logical(1))
  scale <- plot$scales$scales[[which(x_scales)[1]]]

  expect_equal(plot$labels$x, "Particle size (um)")
  expect_equal(scale$limits, log10(c(1, 10000)))
  expect_equal(scale$breaks(c(1, 10000)), c(1, 10, 100, 1000, 10000))
  expect_equal(scale$labels(c(1, 10, 100, 1000, 10000)), c("1", "10", "100", "1000", "10000"))
})

test_that("combined distribution plot uses grey bars and a thick black cumulative line", {
  plot <- plot_distribution(plot_distribution_test_gsd(), sample_id = "A", cumulative = TRUE)
  col_layers <- vapply(plot$layers, function(layer) inherits(layer$geom, "GeomRect"), logical(1))
  line_layers <- vapply(plot$layers, function(layer) inherits(layer$geom, "GeomLine"), logical(1))
  col_layer <- plot$layers[[which(col_layers)[1]]]
  line_layer <- plot$layers[[which(line_layers)[1]]]
  col_color <- if (is.null(col_layer$aes_params$colour)) col_layer$aes_params$color else col_layer$aes_params$colour
  line_color <- if (is.null(line_layer$aes_params$colour)) line_layer$aes_params$color else line_layer$aes_params$colour

  expect_equal(col_layer$aes_params$fill, "grey75")
  expect_equal(col_color, "black")
  expect_equal(line_color, "black")
  expect_gte(line_layer$aes_params$linewidth, 1)
})

test_that("log10 distribution bars use class boundaries", {
  plot <- plot_distribution(plot_distribution_test_gsd(), sample_id = "A")
  rect_layers <- vapply(plot$layers, function(layer) inherits(layer$geom, "GeomRect"), logical(1))
  rect_data <- plot$layers[[which(rect_layers)[1]]]$data

  expect_true(all(c("xmin", "xmax") %in% names(rect_data)))
  expect_equal(rect_data$xmin[1], 2)
  expect_equal(rect_data$xmax[1], 10)
  expect_equal(tail(rect_data$xmin, 1), 0.001)
  expect_equal(tail(rect_data$xmax, 1), 0.125)
})
