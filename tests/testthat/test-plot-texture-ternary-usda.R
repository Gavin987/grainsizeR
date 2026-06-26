usda_plot_root <- function() {
  candidates <- c(
    ".",
    file.path("..", ".."),
    file.path("..", "00_pkg_src", "grainsizeR"),
    file.path("..", "..", "00_pkg_src", "grainsizeR")
  )
  root <- candidates[file.exists(file.path(candidates, "DESCRIPTION"))][1]
  expect_false(is.na(root))
  root
}

usda_plot_gsd <- function() {
  x <- data.frame(
    sample_id = c(rep("A", 12), rep("B", 12)),
    size_mm = rep(c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.031, 0.016, 0.008, 0.004, 0.002, 0.001), 2),
    retained_proportion = c(
      0.01, 0.02, 0.04, 0.08, 0.15, 0.15, 0.14, 0.12, 0.10, 0.08, 0.06, 0.05,
      0.01, 0.01, 0.02, 0.04, 0.08, 0.10, 0.12, 0.14, 0.16, 0.14, 0.10, 0.08
    )
  )
  as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
}

test_that("USDA ternary plotting draws internal boundaries and class labels", {
  plot <- suppressWarnings(plot_texture_ternary(usda_plot_gsd(), scheme = "usda_tt", labels = FALSE))

  boundary_rows <- sum(vapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && all(c("xend", "yend") %in% names(data))) {
      return(nrow(data))
    }
    0L
  }, integer(1)))
  class_labels <- unlist(lapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && "class_label" %in% names(data)) {
      return(data$class_label)
    }
    character()
  }))

  expect_s3_class(plot, "ggplot")
  expect_gt(length(plot$layers), 3)
  expect_gt(boundary_rows, 0)
  expect_equal(length(unique(class_labels)), 12)

  outline <- plot$layers[[1]]
  boundary_layers <- vapply(plot$layers, function(layer) {
    data <- layer$data
    is.data.frame(data) && all(c("xend", "yend") %in% names(data))
  }, logical(1))
  boundary <- plot$layers[[which(boundary_layers)[1]]]
  boundary_color <- if (is.null(boundary$aes_params$colour)) boundary$aes_params$color else boundary$aes_params$colour
  expect_equal(boundary$aes_params$linetype, "solid")
  expect_equal(boundary_color, "black")
  expect_equal(boundary$aes_params$linewidth, outline$aes_params$linewidth)
})

test_that("USDA ternary plotting draws ternary axis labels without Cartesian axes", {
  samples <- data.frame(
    sample_id = c("sand demo", "loam demo", "clay demo"),
    sand = c(92, 42, 22),
    silt = c(5, 38, 22),
    clay = c(3, 20, 56)
  )

  plot <- plot_texture_ternary(
    samples,
    scheme = "usda_tt",
    point_id = "sample_id",
    show_sample_labels = FALSE
  )
  guide_labels <- unlist(lapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && "label" %in% names(data)) {
      return(data$label)
    }
    character()
  }))

  expect_true(all(c("percent sand", "percent silt", "percent clay") %in% guide_labels))
  expect_false(any(c("Sand", "Silt", "Clay") %in% guide_labels))
  expect_true(all(as.character(seq(10, 100, by = 10)) %in% guide_labels))
  expect_equal(plot$labels$x, NULL)
  expect_equal(plot$labels$y, NULL)
  expect_s3_class(plot$theme$axis.text, "element_blank")
  expect_s3_class(plot$theme$axis.ticks, "element_blank")
})

test_that("USDA ternary plotting accepts sand-silt-clay data frames", {
  samples <- data.frame(
    sample_id = c("sand demo", "loam demo", "clay demo"),
    sand = c(92, 42, 22),
    silt = c(5, 38, 22),
    clay = c(3, 20, 56)
  )

  plot <- plot_texture_ternary(
    samples,
    scheme = "usda_tt",
    point_id = "sample_id",
    show_sample_labels = FALSE
  )

  expect_s3_class(plot, "ggplot")
  expect_true(any(vapply(plot$layers, function(layer) {
    data <- layer$data
    is.data.frame(data) && all(c("xend", "yend") %in% names(data))
  }, logical(1))))
})

test_that("USDA ternary plotting does not use soiltexture", {
  root <- usda_plot_root()
  r_files <- list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE)
  r_text <- paste(unlist(lapply(r_files, readLines, warn = FALSE)), collapse = "\n")

  expect_false(grepl(paste0("soiltexture", "::"), r_text, fixed = TRUE))
  expect_false(grepl("library\\(soiltexture\\)|require\\(soiltexture\\)", r_text))
})
