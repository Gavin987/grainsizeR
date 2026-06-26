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
    "requires columns"
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
