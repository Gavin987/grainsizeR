example_path <- function(file) {
  path <- system.file("extdata", file, package = "grainsizeR")
  if (!nzchar(path)) {
    path <- file.path("..", "..", "inst", "extdata", file)
  }
  path
}

example_polygons <- function() {
  data.frame(
    scheme = "synthetic_ternary",
    class_id = "all",
    class_name = "Synthetic full ternary area",
    vertex_id = 1:3,
    left = c(100, 0, 0),
    right = c(0, 100, 0),
    top = c(0, 0, 100),
    left_component = "sand",
    right_component = "silt",
    top_component = "clay",
    reference_id = NA_character_,
    reference = NA_character_
  )
}

example_texture_gsd <- function() {
  x <- data.frame(
    sample_id = rep(c("A", "B"), each = 4),
    size_mm = rep(c(2, 0.05, 0.002, 0.001), 2),
    retained = c(10, 40, 30, 20, 5, 20, 35, 40)
  )

  as_gsd_tbl(x, sample_id, size_mm, retained, value_type = "percent")
}

test_that("documented example data and workflow functions run", {
  long_file <- example_path("grain.long.csv")
  wide_file <- example_path("grain.wide.csv")

  expect_true(file.exists(long_file))
  expect_true(file.exists(wide_file))

  gs <- read_gsd(
    long_file,
    format = "long",
    sample_col = "sample",
    size_col = "size",
    value_col = "proportion",
    size_unit = "mm",
    value_type = "proportion"
  )
  gs_wide <- read_gsd(
    wide_file,
    format = "wide",
    size_col = 1,
    size_unit = "mm",
    value_type = "percent"
  )

  expect_s3_class(gs, "gsd_tbl")
  expect_s3_class(gs_wide, "gsd_tbl")
  expect_s3_class(gs_d_values(gs, probs = c(10, 50, 90), extrapolate = "warn_linear"), "tbl_df")
  expect_s3_class(
    suppressWarnings(gs_percent_finer(
      gs,
      sizes = c(2, 20, 50, 60, 63),
      size_unit = "um",
      extrapolate = "warn_linear"
    )),
    "tbl_df"
  )
  expect_s3_class(suppressWarnings(gs_grain_size_indices(gs, extrapolate = "warn_linear")), "tbl_df")
  expect_s3_class(suppressWarnings(gs_folk_ward(gs, extrapolate = "warn_linear")), "tbl_df")
  expect_s3_class(suppressWarnings(gs_moments(gs, open_end = "extend_phi")), "tbl_df")
  expect_s3_class(gs_fractions_wide(gs, scheme = "wentworth_major"), "tbl_df")

  expect_s3_class(plot_distribution(gs, sample_id = unique(gs$sample_id)[1]), "ggplot")
  expect_s3_class(
    suppressWarnings(plot_cumulative(gs, sample_id = unique(gs$sample_id)[1], show_percentiles = c(10, 50, 90), extrapolate = "warn_linear")),
    "ggplot"
  )
  expect_s3_class(plot_fractions(gs, scheme = "wentworth_major"), "ggplot")
})

test_that("synthetic polygon examples validate and classify", {
  polygons <- validate_texture_polygons(example_polygons())
  synthetic_gs <- example_texture_gsd()

  classified <- classify_texture(
    synthetic_gs,
    polygons = polygons,
    scheme = "synthetic_ternary"
  )

  expect_s3_class(polygons, "texture_polygons")
  expect_s3_class(classified, "tbl_df")
  expect_true(all(classified$class_id == "all"))
  expect_s3_class(
    plot_texture_triangle(
      synthetic_gs,
      polygons = polygons,
      scheme = "synthetic_ternary"
    ),
    "ggplot"
  )
})
