test_that("preferred API functions and compatibility aliases are exported", {
  exports <- getNamespaceExports("grainsizeR")
  preferred <- c(
    "read_gsd",
    "read_gsd_wide",
    "as_gsd_tbl",
    "is_gsd_tbl",
    "validate_gsd_tbl",
    "gs_d_values",
    "gs_d_spread",
    "gs_percent_finer",
    "gs_grain_size_indices",
    "gs_modes",
    "gs_size_terms",
    "gs_describe_parameters",
    "gs_quality_flags",
    "gs_gradistat_sediment_name",
    "gs_folk_ward",
    "gs_moments",
    "gs_parameters",
    "particle_size_systems",
    "gs_fraction_schemes",
    "gs_fractions",
    "gs_fractions_wide",
    "plot_distribution",
    "plot_cumulative",
    "plot_fractions",
    "plot_texture_ternary",
    "plot_gradistat_summary",
    "texture_polygon_template",
    "validate_texture_polygons",
    "classify_texture",
    "texture_polygon_sources",
    "texture_source_audit",
    "texture_polygon_reconstruction_template",
    "reconstruction_to_texture_polygons"
  )
  aliases <- c("gs_percentile", "gs_engineering", "gs_folkward", "plot_texture_triangle", "plot_trigon")

  expect_true(all(preferred %in% exports))
  expect_true(all(aliases %in% exports))
  expect_false("export_gradistat_summary" %in% exports)
})

test_that("example data files are present and package data do not include polygon coordinates", {
  expect_true(file.exists(system.file("extdata", "grain.long.csv", package = "grainsizeR")))
  expect_true(file.exists(system.file("extdata", "grain.wide.csv", package = "grainsizeR")))

  data_files <- if (dir.exists("data")) {
    list.files("data", recursive = TRUE, full.names = FALSE)
  } else {
    character()
  }
  extdata_files <- list.files(file.path("inst", "extdata"), recursive = TRUE, full.names = FALSE)

  expect_false(any(grepl("polygon|coordinate|reconstruction", data_files, ignore.case = TRUE)))
  expect_false(any(grepl("polygon|coordinate|reconstruction", extdata_files, ignore.case = TRUE)))
})

test_that("source audit excludes out-of-scope systems", {
  audit <- texture_source_audit()

  expect_false(any(c("aashto", "uscs") %in% audit$scheme))
})

test_that("DESCRIPTION and README contain release-candidate-safe metadata", {
  desc_file <- c(
    "DESCRIPTION",
    file.path("..", "..", "DESCRIPTION"),
    file.path("..", "00_pkg_src", "grainsizeR", "DESCRIPTION"),
    file.path("..", "..", "00_pkg_src", "grainsizeR", "DESCRIPTION")
  )
  desc_file <- desc_file[file.exists(desc_file)][1]
  expect_false(is.na(desc_file))
  desc <- paste(readLines(desc_file, warn = FALSE), collapse = "\n")
  desc_dcf <- read.dcf(desc_file)
  expect_identical(unname(desc_dcf[1, "Package"]), "grainsizeR")
  expect_true(grepl("https://github.com/Gavin987/grainsizeR", desc_dcf[1, "URL"], fixed = TRUE))
  expect_true(grepl("cschang.bt10@nycu.edu.tw", desc, fixed = TRUE))

  readme_file <- c(
    "README.md",
    file.path("..", "..", "README.md"),
    file.path("..", "00_pkg_src", "grainsizeR", "README.md"),
    file.path("..", "..", "00_pkg_src", "grainsizeR", "README.md")
  )
  readme_file <- readme_file[file.exists(readme_file)][1]
  expect_false(is.na(readme_file))
  readme <- paste(readLines(readme_file, warn = FALSE), collapse = "\n")

  expect_true(grepl("install.packages(\"remotes\")", readme, fixed = TRUE))
  expect_true(grepl("remotes::install_github(\"Gavin987/grainsizeR\")", readme, fixed = TRUE))
  expect_true(grepl("library(grainsizeR)", readme, fixed = TRUE))
  placeholder_owner <- paste0("<", "OWNER", ">/")
  expect_false(grepl(placeholder_owner, readme, fixed = TRUE))
  expect_false(grepl("built-in official texture polygon datasets are available", readme, ignore.case = TRUE))
  expect_false(grepl("civil[- ]engineering classification", readme, ignore.case = TRUE))
})
