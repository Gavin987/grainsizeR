readme_figure_files <- c(
  "man/figures/readme-wide-distribution.png",
  "man/figures/readme-wide-cumulative.png",
  "man/figures/readme-wide-fractions.png",
  "man/figures/readme-gradistat-ternary.png",
  "man/figures/readme-usda-ternary.png"
)

readme_repo_root <- function() {
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

readme_test_path <- function(...) {
  path <- file.path(readme_repo_root(), ...)
  if (file.exists(path)) {
    return(path)
  }

  installed <- system.file(..., package = "grainsizeR")
  if (nzchar(installed)) {
    return(installed)
  }

  path
}

readme_example_path <- function(file) {
  source_path <- file.path(readme_repo_root(), "inst", "extdata", file)
  if (file.exists(source_path)) {
    return(source_path)
  }

  installed <- system.file("extdata", file, package = "grainsizeR")
  if (!nzchar(installed)) {
    stop("Missing bundled example file: ", file, call. = FALSE)
  }
  installed
}

test_that("README figure generation script is present", {
  script_path <- readme_test_path("data-raw", "readme-figures.R")
  if (!file.exists(script_path)) {
    skip("README figure generation script is not included in this installed test context")
  }

  script <- readLines(script_path, warn = FALSE)
  script_text <- paste(script, collapse = "\n")

  expect_false(any(grepl("[A-Za-z]:[\\/]", script)))
  expect_true(all(vapply(basename(readme_figure_files), grepl, logical(1), x = script_text, fixed = TRUE)))
  expect_true(grepl("plot_distribution\\([^\\n]+cumulative = TRUE", script_text))
  expect_true(grepl("wide_plot_sample <-", script_text, fixed = TRUE))
  expect_true(grepl("sample_id = wide_plot_sample", script_text, fixed = TRUE))
  expect_true(grepl("scheme = \"gravel_sand_mud\"", script_text, fixed = TRUE))
  expect_true(grepl("fill_palette = \"YlOrBr\"", script_text, fixed = TRUE))
  expect_true(grepl("show_sample_labels = FALSE", script_text, fixed = TRUE))
})

test_that("README references stable existing figure files", {
  readme_path <- readme_test_path("README.Rmd")
  if (!file.exists(readme_path)) {
    skip("README.Rmd is not available")
  }

  readme <- paste(readLines(readme_path, warn = FALSE), collapse = "\n")
  referenced <- regmatches(
    readme,
    gregexpr("man/figures/readme-[A-Za-z0-9-]+\\.png", readme)
  )[[1]]

  expect_setequal(unique(referenced), readme_figure_files)
  expect_false(any(grepl("[A-Za-z]:[\\/]", referenced)))
  expect_true(all(file.exists(vapply(unique(referenced), function(x) readme_test_path(x), character(1)))))
})

test_that("bundled examples support README ternary plot workflows", {
  wide <- read_gsd(readme_example_path("grain.wide.csv"), format = "wide")
  long <- read_gsd(readme_example_path("grain.long.csv"))

  wide_fractions <- suppressWarnings(gs_fractions_wide(wide, scheme = "gravel_sand_mud"))
  gsm <- data.frame(
    sample_id = wide_fractions$sample_id,
    gravel = wide_fractions$gravel_percent,
    sand = wide_fractions$sand_percent,
    mud = wide_fractions$mud_percent
  )
  gsm <- gsm[stats::complete.cases(gsm[c("gravel", "sand", "mud")]), ]

  expect_s3_class(
    plot_texture_ternary(
      gsm,
      scheme = "gradistat",
      basis = "gravel_sand_mud",
      point_id = "sample_id",
      show_sample_labels = FALSE
    ),
    "ggplot"
  )
  expect_s3_class(suppressWarnings(plot_texture_ternary(long, scheme = "usda_tt", labels = FALSE)), "ggplot")
})

test_that("README examples do not call gs_fw57 on open-tail long data by default", {
  root <- readme_repo_root()
  files <- c(
    file.path(root, "README.Rmd"),
    file.path(root, "README.md"),
    list.files(file.path(root, "vignettes"), pattern = "[.]Rmd$", full.names = TRUE)
  )
  text <- paste(unlist(lapply(files[file.exists(files)], readLines, warn = FALSE)), collapse = "\n")

  expect_false(grepl("gs_fw57\\(\\s*long\\s*\\)", text))
  expect_false(grepl("gs_folk_ward\\(\\s*long\\s*\\)", text))
})
