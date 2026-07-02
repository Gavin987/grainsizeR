plot_contract_root <- function() {
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

plot_contract_gsd <- function() {
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

plot_contract_fine_gsd <- function() {
  x <- data.frame(
    sample_id = "A",
    size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.031, 0.016, 0.008, 0.004, 0.002, 0.001),
    retained_proportion = c(0.02, 0.03, 0.05, 0.10, 0.15, 0.18, 0.12, 0.10, 0.08, 0.07, 0.06, 0.04)
  )
  as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
}

test_that("documented plot functions exist", {
  for (fn in c(
    "plot_distribution", "plot_cumulative", "plot_fractions",
    "plot_texture_triangle", "plot_trigon"
  )) {
    expect_true(exists(fn, envir = asNamespace("grainsizeR"), mode = "function"))
  }
})

test_that("distribution and cumulative plots support documented scale behavior", {
  gsd <- plot_contract_gsd()

  expect_s3_class(plot_distribution(gsd, sample_id = "A", x_scale = "log10"), "ggplot")
  expect_s3_class(plot_distribution(gsd, sample_id = "A", x_scale = "phi", type = "line"), "ggplot")
  expect_s3_class(plot_distribution(gsd, sample_id = "A", x_scale = "linear_um"), "ggplot")
  combined <- plot_distribution(gsd, sample_id = "A", cumulative = TRUE)
  expect_s3_class(combined, "ggplot")
  expect_true(any(vapply(combined$layers, function(layer) inherits(layer$geom, "GeomCol"), logical(1))))
  expect_true(any(vapply(combined$layers, function(layer) inherits(layer$geom, "GeomLine"), logical(1))))

  expect_s3_class(plot_cumulative(gsd, sample_id = "A", x_scale = "log10"), "ggplot")
  expect_s3_class(plot_cumulative(gsd, sample_id = "A", x_scale = "phi"), "ggplot")
  expect_s3_class(plot_cumulative(gsd, sample_id = "A", x_scale = "linear_um"), "ggplot")
  expect_s3_class(
    plot_cumulative(gsd, sample_id = "A", show_percentiles = c(10, 50, 90), extrapolate = "warn_linear"),
    "ggplot"
  )
})

test_that("distribution and cumulative plots are single-sample with plain millimetre log ticks", {
  gsd <- plot_contract_gsd()

  expect_error(plot_distribution(gsd), "plots one sample at a time")
  expect_error(plot_cumulative(gsd), "plots one sample at a time")

  combined <- plot_distribution(gsd, sample_id = "A", cumulative = TRUE)
  cumulative <- plot_cumulative(gsd, sample_id = "A")
  for (plot in list(combined, cumulative)) {
    x_scales <- vapply(plot$scales$scales, function(scale) "x" %in% scale$aesthetics, logical(1))
    scale <- plot$scales$scales[[which(x_scales)[1]]]
    breaks <- scale$breaks(c(0.001, 10))

    expect_s3_class(plot$facet, "FacetNull")
    expect_equal(plot$labels$x, "Particle size (mm)")
    expect_equal(scale$limits, log10(c(0.001, 10)))
    expect_equal(scale$labels(c(0.001, 0.01, 0.1, 1, 10)), c("0.001", "0.01", "0.1", "1", "10"))
    expect_true(all(c(0.001, 0.01, 0.1, 1, 10) %in% breaks))
  }
})

test_that("exported plotting functions use theme_bw-compatible defaults", {
  gsd <- plot_contract_gsd()
  gsm <- data.frame(sample_id = c("A", "B"), gravel = c(0, 40), sand = c(95, 40), mud = c(5, 20))

  plots <- list(
    plot_distribution(gsd, sample_id = "A"),
    plot_cumulative(gsd, sample_id = "A"),
    suppressWarnings(plot_fractions(gsd, scheme = "gravel_sand_mud")),
    plot_texture_triangle(gsm, scheme = "gradistat", basis = "gravel_sand_mud", point_id = "sample_id"),
    suppressWarnings(plot_trigon(plot_contract_fine_gsd(), scheme = "usda"))
  )

  for (plot in plots) {
    expect_equal(plot$theme$panel.background$fill, "white")
  }
})

test_that("fraction plots and texture ternary plots return ggplot objects", {
  gsd <- plot_contract_gsd()
  gsm <- data.frame(sample_id = c("A", "B"), gravel = c(0, 40), sand = c(95, 40), mud = c(5, 20))
  ssc <- data.frame(sample_id = c("A", "B"), sand = c(95, 20), silt = c(3, 60), clay = c(2, 20))

  expect_s3_class(suppressWarnings(plot_fractions(gsd, scheme = "wentworth_major")), "ggplot")
  fraction_plot <- suppressWarnings(plot_fractions(gsd, scheme = "gravel_sand_mud", fill_palette = "YlOrBr"))
  expect_s3_class(fraction_plot, "ggplot")
  fill_scales <- vapply(fraction_plot$scales$scales, function(scale) "fill" %in% scale$aesthetics, logical(1))
  expect_equal(fraction_plot$scales$scales[[which(fill_scales)[1]]]$breaks, c("gravel", "sand", "mud"))
  expect_s3_class(
    plot_texture_triangle(gsm, scheme = "gradistat", basis = "gravel_sand_mud", point_id = "sample_id"),
    "ggplot"
  )
  expect_s3_class(
    plot_texture_triangle(ssc, scheme = "gradistat", basis = "sand_silt_clay_no_gravel", point_id = "sample_id"),
    "ggplot"
  )
  expect_s3_class(
    suppressWarnings(plot_texture_triangle(plot_contract_fine_gsd(), scheme = "usda")),
    "ggplot"
  )
})

test_that("plot API errors remain clear for invalid input", {
  expect_error(plot_distribution(data.frame()), "must be a gsd_tbl")
  expect_error(plot_cumulative(data.frame()), "must be a gsd_tbl")
  expect_error(plot_fractions(data.frame()), "must be a gsd_tbl")
  expect_error(
    plot_texture_triangle(
      data.frame(sample_id = "A", gravel = 1, sand = 1, mud = 1),
      scheme = "gradistat",
      basis = "gravel_sand_mud"
    ),
    "sum to approximately 100"
  )
})

test_that("plot API contract does not add forbidden plotting dependencies", {
  root <- plot_contract_root()
  description <- read.dcf(file.path(root, "DESCRIPTION"))
  dependency_text <- paste(description[, intersect(colnames(description), c("Imports", "Depends", "Suggests"))], collapse = "\n")
  r_files <- list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE)
  r_text <- paste(unlist(lapply(r_files, readLines, warn = FALSE)), collapse = "\n")

  forbidden <- "soiltexture"
  call_pattern <- paste0("\\b", forbidden, "::|library\\(", forbidden, "\\)|require\\(", forbidden, "\\)")
  expect_false(grepl(paste0("\\b", forbidden, "\\b"), dependency_text, ignore.case = TRUE))
  expect_false(grepl(call_pattern, r_text, ignore.case = TRUE))
  expect_false(grepl("\\bggtern\\b|\\bplotly\\b", dependency_text, ignore.case = TRUE))
})
