workflow_vignette_root <- function() {
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

workflow_vignette_text <- function(root) {
  files <- file.path(root, "vignettes", c(
    "grain-size-workflow.Rmd",
    "texture-classification.Rmd",
    "replacing-gradistat-g2sd.Rmd"
  ))
  paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
}

strip_workflow_markdown_code <- function(text) {
  text <- gsub("```[\\s\\S]*?```", "", text, perl = TRUE)
  gsub("`[^`]*`", "", text, perl = TRUE)
}

test_that("full workflow vignettes exist", {
  root <- workflow_vignette_root()
  expected <- file.path(root, "vignettes", c(
    "grain-size-workflow.Rmd",
    "texture-classification.Rmd",
    "replacing-gradistat-g2sd.Rmd"
  ))

  expect_true(all(file.exists(expected)))
})

test_that("workflow vignettes use required terminology and capitalization", {
  root <- workflow_vignette_root()
  text <- workflow_vignette_text(root)
  prose_text <- strip_workflow_markdown_code(text)

  expect_true(grepl("\\bGRADISTAT\\b", prose_text))
  expect_true(grepl("\\bG2Sd\\b", prose_text))
  bad_gradistat <- paste(c(
    paste0("\\b", "Gradi", "stat", "\\b"),
    paste0("\\b", "GRAD", "STAT", "\\b"),
    paste0("\\b", "GRD", "ISTAT", "\\b")
  ), collapse = "|")
  bad_g2sd <- paste(c(
    paste0("\\b", "G2", "SD", "\\b"),
    paste0("\\b", "G2", "sd", "\\b")
  ), collapse = "|")
  bad_ternary <- paste(c(
    paste("triangle", "plot"),
    paste("triangle", "plots"),
    paste("texture", "triangle", "plot"),
    paste("texture", "triangle", "plots")
  ), collapse = "|")
  expect_false(grepl(bad_gradistat, prose_text))
  expect_false(grepl(bad_g2sd, prose_text))
  expect_true(grepl("ternary plot", prose_text, ignore.case = TRUE))
  expect_false(grepl(bad_ternary, prose_text, ignore.case = TRUE))
})

test_that("workflow vignettes cover key public functions", {
  text <- workflow_vignette_text(workflow_vignette_root())
  expected <- c(
    "gs_d_values",
    "gs_d_spread",
    "gs_folk_ward",
    "gs_moments",
    "gs_modes",
    "gs_fractions",
    "gs_describe_parameters",
    "gs_quality_flags",
    "classify_texture",
    "plot_distribution",
    "plot_cumulative",
    "plot_fractions",
    "plot_texture_triangle"
  )

  for (fn in expected) {
    expect_true(grepl(fn, text, fixed = TRUE), info = fn)
  }
})

test_that("README includes an end-to-end workflow example", {
  root <- workflow_vignette_root()
  readme_path <- file.path(root, "README.Rmd")
  if (!file.exists(readme_path)) {
    readme_path <- file.path(root, "README.md")
  }
  expect_true(file.exists(readme_path))
  readme <- paste(readLines(readme_path, warn = FALSE), collapse = "\n")

  expect_true(grepl("End-to-End Workflow", readme, fixed = TRUE))
  expect_true(grepl("gs_d_values", readme, fixed = TRUE))
  expect_true(grepl("plot_distribution", readme, fixed = TRUE))
  expect_true(grepl("plot_texture_triangle", readme, fixed = TRUE))
})
