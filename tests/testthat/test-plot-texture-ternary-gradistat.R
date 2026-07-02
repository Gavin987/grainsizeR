gradistat_ternary_plot_root <- function() {
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

test_that("plot_texture_triangle supports GRADISTAT gravel-sand-mud ternary plots", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    gravel = c(0, 10, 40),
    sand = c(95, 80, 40),
    mud = c(5, 10, 20)
  )

  plot <- plot_texture_triangle(
    samples,
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id"
  )

  expect_s3_class(plot, "ggplot")
})

test_that("plot_texture_triangle forwards to plot_texture_ternary", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    gravel = c(0, 10, 40),
    sand = c(95, 80, 40),
    mud = c(5, 10, 20)
  )

  ternary <- plot_texture_ternary(samples, scheme = "gradistat", point_id = "sample_id")
  triangle <- plot_texture_triangle(samples, scheme = "gradistat", point_id = "sample_id")

  expect_s3_class(triangle, "ggplot")
  expect_equal(length(triangle$layers), length(ternary$layers))
  expect_equal(vapply(triangle$layers, function(layer) class(layer$geom)[1], character(1)),
               vapply(ternary$layers, function(layer) class(layer$geom)[1], character(1)))
})

test_that("plot_texture_ternary accepts official GRADISTAT fraction outputs", {
  path <- system.file("extdata", "grain.wide.csv", package = "grainsizeR")
  if (!nzchar(path)) {
    path <- file.path("..", "..", "inst", "extdata", "grain.wide.csv")
  }
  wide <- read_gsd(
    path,
    format = "wide",
    value_type = "percent"
  )

  frac <- suppressWarnings(gs_fractions(wide, scheme = "gravel_sand_mud"))
  expect_no_error(plot_texture_ternary(frac, scheme = "gradistat"))

  frac_wide <- suppressWarnings(gs_fractions_wide(wide, scheme = "gravel_sand_mud"))
  expect_no_error(plot_texture_ternary(frac_wide, scheme = "gradistat"))

  gradistat_wide <- suppressWarnings(gs_fractions_wide(wide, scheme = "gradistat"))
  expect_no_error(plot_texture_ternary(gradistat_wide, scheme = "gradistat"))
  expect_no_error(plot_texture_triangle(gradistat_wide, scheme = "gradistat"))
  expect_no_error(plot_texture_triangle(frac_wide, scheme = "gradistat"))
})

test_that("plot_texture_ternary accepts case-only component name variants", {
  ternary <- tibble::tibble(
    sample_id = "A",
    Gravel = 10,
    Sand = 80,
    Mud = 10
  )

  expect_no_error(plot_texture_ternary(ternary, scheme = "gradistat"))
})

test_that("plot_texture_ternary hides sample labels by default and can opt in", {
  ternary <- tibble::tibble(
    sample_id = c("A", "B"),
    gravel = c(10, 20),
    sand = c(80, 70),
    mud = c(10, 10)
  )

  default_plot <- plot_texture_ternary(ternary, scheme = "gradistat", point_id = "sample_id")
  labeled_plot <- plot_texture_ternary(
    ternary,
    scheme = "gradistat",
    point_id = "sample_id",
    show_sample_labels = TRUE
  )

  has_sample_label_layer <- function(plot) {
    any(vapply(plot$layers, function(layer) {
      data <- layer$data
      inherits(layer$geom, "GeomText") && is.data.frame(data) && "point_label" %in% names(data)
    }, logical(1)))
  }

  expect_false(has_sample_label_layer(default_plot))
  expect_true(has_sample_label_layer(labeled_plot))
})

test_that("plot_texture_ternary accepts point aesthetics and grouped colors", {
  ternary <- tibble::tibble(
    sample_id = c("A", "B"),
    season = c("dry", "wet"),
    gravel = c(10, 20),
    sand = c(80, 70),
    mud = c(10, 10)
  )

  constant_plot <- plot_texture_ternary(
    ternary,
    scheme = "gradistat",
    point_size = 2,
    point_color = "black",
    point_alpha = 0.8
  )
  point_layers <- which(vapply(constant_plot$layers, function(layer) inherits(layer$geom, "GeomPoint"), logical(1)))
  point_layer <- constant_plot$layers[[point_layers[length(point_layers)]]]
  point_color <- if (is.null(point_layer$aes_params$colour)) point_layer$aes_params$color else point_layer$aes_params$colour
  expect_equal(point_color, "black")
  expect_equal(point_layer$aes_params$size, 2)
  expect_equal(point_layer$aes_params$alpha, 0.8)

  grouped_plot <- plot_texture_ternary(ternary, scheme = "gradistat", color_by = "season")
  grouped_point <- grouped_plot$layers[[tail(which(vapply(grouped_plot$layers, function(layer) {
    inherits(layer$geom, "GeomPoint") && is.data.frame(layer$data) && "season" %in% names(layer$data)
  }, logical(1))), 1)]]
  expect_true("colour" %in% names(grouped_point$mapping))
  expect_error(
    plot_texture_ternary(ternary, scheme = "gradistat", color_by = "missing"),
    "`color_by`"
  )
})

test_that("plot_texture_ternary rejects raw GRADISTAT gsd_tbl input with workflow guidance", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )

  expect_error(
    plot_texture_ternary(gsd, scheme = "gradistat"),
    "expects summarized ternary components"
  )
})

test_that("plot_texture_ternary rejects unsupported diagram schemes early", {
  ternary <- tibble::tibble(
    sample_id = "A",
    gravel = 10,
    sand = 80,
    mud = 10
  )

  expect_error(
    plot_texture_ternary(ternary, scheme = "isss"),
    "`scheme` must be one of"
  )
})

test_that("plot_texture_triangle supports GRADISTAT sand-silt-clay no-gravel ternary plots", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    sand = c(95, 60, 20),
    silt = c(3, 30, 60),
    clay = c(2, 10, 20)
  )

  plot <- plot_texture_triangle(
    samples,
    scheme = "gradistat",
    basis = "sand_silt_clay_no_gravel",
    point_id = "sample_id"
  )

  expect_s3_class(plot, "ggplot")
})

test_that("classified GRADISTAT outputs can be drawn as ternary plots", {
  classified <- classify_texture(
    data.frame(sample_id = c("A", "B"), gravel = c(0, 40), sand = c(95, 40), mud = c(5, 20)),
    scheme = "gradistat",
    method = "rules",
    basis = "gravel_sand_mud"
  )

  plot <- plot_texture_triangle(
    classified,
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id"
  )

  expect_s3_class(plot, "ggplot")
})

test_that("GRADISTAT ternary plot validation cases plot or fail as expected", {
  cases <- data.frame(
    case_id = c("gsm_sand", "gsm_gravelly_sand", "ssc_sand", "ssc_silt", "gsm_bad_sum", "ssc_bad_sum"),
    ternary_basis = c(
      "gravel_sand_mud",
      "gravel_sand_mud",
      "sand_silt_clay_no_gravel",
      "sand_silt_clay_no_gravel",
      "gravel_sand_mud",
      "sand_silt_clay_no_gravel"
    ),
    gravel = c(0, 10, NA, NA, 10, NA),
    sand = c(95, 85, 95, 5, 40, 60),
    mud = c(5, 5, NA, NA, 40, NA),
    silt = c(NA, NA, 3, 90, NA, 20),
    clay = c(NA, NA, 2, 5, NA, 10),
    expected_plot_status = c("plotted", "plotted", "plotted", "plotted", "invalid", "invalid")
  )
  plotted <- cases[cases$expected_plot_status == "plotted", ]
  for (basis in unique(plotted$ternary_basis)) {
    one <- plotted[plotted$ternary_basis == basis, ]
    input <- if (basis == "gravel_sand_mud") {
      one[c("case_id", "gravel", "sand", "mud")]
    } else {
      one[c("case_id", "sand", "silt", "clay")]
    }

    expect_s3_class(
      plot_texture_triangle(input, scheme = "gradistat", basis = basis, point_id = "case_id"),
      "ggplot"
    )
  }

  invalid <- cases[cases$expected_plot_status == "invalid", ]
  for (i in seq_len(nrow(invalid))) {
    input <- if (invalid$ternary_basis[i] == "gravel_sand_mud") {
      invalid[i, c("case_id", "gravel", "sand", "mud")]
    } else {
      invalid[i, c("case_id", "sand", "silt", "clay")]
    }
    expect_error(
      plot_texture_triangle(input, scheme = "gradistat", basis = invalid$ternary_basis[i]),
      "sum to approximately 100"
    )
  }
})

test_that("GRADISTAT ternary plotting validates required columns and point labels", {
  expect_error(
    plot_texture_triangle(data.frame(sand = 95, mud = 5), scheme = "gradistat", basis = "gravel_sand_mud"),
    "must include columns"
  )
  expect_error(
    plot_texture_triangle(
      data.frame(gravel = 0, sand = 95, mud = 5),
      scheme = "gradistat",
      basis = "gravel_sand_mud",
      point_id = "missing"
    ),
    "`point_id`"
  )
})

test_that("GRADISTAT ternary plotting supports readable class labels and hidden sample labels", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    gravel = c(0, 10, 40),
    sand = c(95, 80, 40),
    mud = c(5, 10, 20)
  )

  plot <- plot_texture_triangle(
    samples,
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id",
    show_sample_labels = FALSE,
    class_label_size = 2.1
  )

  label_data <- unlist(lapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && "class_label" %in% names(data)) {
      return(data$class_label)
    }
    character()
  }))

  sample_label_layers <- vapply(plot$layers, function(layer) {
    data <- layer$data
    inherits(layer$geom, "GeomText") && is.data.frame(data) && "point_label" %in% names(data)
  }, logical(1))

  expect_true(any(grepl("\n", label_data, fixed = TRUE)))
  expect_false(any(sample_label_layers))
})

test_that("GRADISTAT ternary plotting uses sediment-oriented ternary axes", {
  samples <- data.frame(
    sample_id = c("mud", "sand", "gravel"),
    gravel = c(0, 0, 100),
    sand = c(0, 100, 0),
    mud = c(100, 0, 0)
  )

  plot <- plot_texture_triangle(
    samples,
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id",
    show_sample_labels = FALSE
  )
  points <- grainsizeR:::.gradistat_ternary_points(samples, "gravel_sand_mud", point_id = "sample_id")
  guide_labels <- unlist(lapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && "label" %in% names(data)) {
      return(data$label)
    }
    character()
  }))

  expect_equal(points$x, c(0, 1, 0.5))
  expect_equal(points$y, c(0, 0, sqrt(3) / 2))
  expect_true(all(c("Mud", "Sand", "Gravel", "Gravel %", "Sand:Mud Ratio", "Trace") %in% guide_labels))
  expect_true(all(c("1:9", "5:5", "9:1") %in% guide_labels))
  axis_tick_data <- unique(do.call(rbind, lapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && all(c("label", "axis", "x", "y", "angle") %in% names(data))) {
      return(data[data$label %in% c("Trace", "5", "30", "80", "100"), c("label", "axis", "x", "y", "angle")])
    }
    data.frame(label = character(), axis = character(), x = numeric(), y = numeric(), angle = numeric())
  })))
  expect_equal(axis_tick_data$y[axis_tick_data$label == "Trace"], sqrt(3) / 2 * 0.05, tolerance = 1e-8)
  expect_equal(axis_tick_data$y[axis_tick_data$label == "5"], sqrt(3) / 2 * 0.10, tolerance = 1e-8)
  expect_true(all(axis_tick_data$angle[axis_tick_data$label %in% c("Trace", "5", "30", "80", "100")] == 0))
  axis_title_data <- unique(do.call(rbind, lapply(plot$layers, function(layer) {
    data <- layer$data
    if (is.data.frame(data) && all(c("label", "x", "y") %in% names(data))) {
      return(data[data$label %in% c("Mud", "Sand", "Gravel"), c("label", "x", "y")])
    }
    data.frame(label = character(), x = numeric(), y = numeric())
  })))
  expect_equal(axis_title_data$x[axis_title_data$label == "Mud"], -0.055)
  expect_equal(axis_title_data$x[axis_title_data$label == "Sand"], 1.055)
  expect_gt(axis_title_data$y[axis_title_data$label == "Gravel"], sqrt(3) / 2)
  expect_equal(plot$labels$x, NULL)
  expect_equal(plot$labels$y, NULL)
  expect_s3_class(plot$theme$axis.text, "element_blank")
  expect_s3_class(plot$theme$axis.ticks, "element_blank")
})

test_that("GRADISTAT gravel-sand-mud boundaries match reference geometry", {
  segments <- grainsizeR:::.gradistat_ternary_segments("gravel_sand_mud")

  expect_true(all(c("Trace", "gravel = 5", "gravel = 30", "gravel = 80") %in% unique(segments$boundary)))
  ratio <- segments[grepl("sand / mud", segments$boundary, fixed = TRUE), ]
  expect_equal(length(unique(ratio$segment_id)), 3)
  expect_equal(min(ratio$y), 0)
  expect_lte(max(ratio$y), sqrt(3) / 2 * 0.8 + 1e-8)
  trace <- segments[segments$boundary == "Trace", ]
  gravel_five <- segments[segments$boundary == "gravel = 5", ]
  expect_equal(length(unique(trace$segment_id)), 1)
  expect_equal(unique(trace$y), sqrt(3) / 2 * 0.05, tolerance = 1e-8)
  expect_equal(unique(gravel_five$y), sqrt(3) / 2 * 0.10, tolerance = 1e-8)
  expect_false(any(ratio$boundary == "sand / mud = 0.111111111111111" & ratio$y > sqrt(3) / 2 * 0.3))
  one_to_nine <- ratio[ratio$boundary == "sand / mud = 0.111111111111111", ]
  five_to_five <- ratio[ratio$boundary == "sand / mud = 1", ]
  nine_to_one <- ratio[ratio$boundary == "sand / mud = 9", ]
  one_to_nine_segments <- split(one_to_nine, one_to_nine$segment_id)
  expect_true(any(vapply(one_to_nine_segments, function(x) {
    isTRUE(all.equal(range(x$y), c(0, sqrt(3) / 2 * 0.10), tolerance = 1e-8))
  }, logical(1))))
  expect_equal(min(five_to_five$y), 0, tolerance = 1e-8)
  expect_equal(max(five_to_five$y), sqrt(3) / 2 * 0.8, tolerance = 1e-8)
  expect_equal(length(unique(five_to_five$segment_id)), 1)
  expect_equal(max(nine_to_one$y), sqrt(3) / 2 * 0.8, tolerance = 1e-8)
  expect_lte(max(ratio$y), sqrt(3) / 2 * 0.8 + 1e-8)
})

test_that("GRADISTAT gravel-sand-mud labels use adjusted readable positions", {
  labels <- grainsizeR:::.gradistat_ternary_labels("gravel_sand_mud")

  slightly <- c(
    "slightly_gravelly_mud",
    "slightly_gravelly_sandy_mud",
    "slightly_gravelly_muddy_sand",
    "slightly_gravelly_sand"
  )
  expect_true(all(slightly %in% labels$class_id[labels$show_label]))
  expect_equal(labels$class_label[labels$class_id == "muddy_sand"], "muddy sand")
  expect_equal(labels$class_label[labels$class_id == "sandy_mud"], "sandy mud")
  expect_equal(labels$class_label[labels$class_id == "gravelly_muddy_sand"], "gravelly muddy sand")
  expect_equal(labels$class_label[labels$class_id == "muddy_sandy_gravel"], "muddy sandy gravel")
  expect_gt(labels$y[labels$class_id == "muddy_sand"], 0)
  expect_gt(labels$y[labels$class_id == "sandy_mud"], 0)
  expect_gt(labels$y[labels$class_id == "mud"], 0)
  expect_gt(labels$y[labels$class_id == "sand"], 0)
  expect_equal(labels$x[labels$class_id == "gravel"], 0.5, tolerance = 1e-8)
})

test_that("GRADISTAT ternary plot uses solid boundaries matching the outline", {
  plot <- plot_texture_triangle(
    data.frame(sample_id = "A", gravel = 40, sand = 40, mud = 20),
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id",
    show_sample_labels = FALSE
  )
  boundary_layers <- vapply(plot$layers, function(layer) {
    data <- layer$data
    is.data.frame(data) && "segment_id" %in% names(data)
  }, logical(1))
  boundary <- plot$layers[[which(boundary_layers)[1]]]
  boundary_color <- if (is.null(boundary$aes_params$colour)) boundary$aes_params$color else boundary$aes_params$colour

  expect_equal(boundary$aes_params$linetype, "solid")
  expect_equal(boundary_color, "black")
  expect_equal(boundary$aes_params$linewidth, plot$layers[[1]]$aes_params$linewidth)
})

test_that("GRADISTAT ternary plotting keeps helpers internal and avoids runtime data", {
  exports <- getNamespaceExports("grainsizeR")
  root <- gradistat_ternary_plot_root()
  data_files <- if (dir.exists(file.path(root, "data"))) {
    list.files(file.path(root, "data"), recursive = TRUE, full.names = FALSE)
  } else {
    character()
  }

  expect_false(any(grepl("gradistat_ternary|gradistat.*boundary", exports)))
  expect_false(any(grepl("gradistat.*ternary|gradistat.*boundary", data_files, ignore.case = TRUE)))
  expect_false(any(grepl("soiltexture", readLines(file.path(root, "R", "gradistat-ternary-boundaries.R"), warn = FALSE), ignore.case = TRUE)))
})
