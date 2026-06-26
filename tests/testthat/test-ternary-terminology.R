ternary_terminology_root <- function() {
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

test_that("texture plotting documentation uses ternary plot terminology", {
  root <- ternary_terminology_root()
  docs <- c(
    file.path(root, "R"),
    file.path(root, "man"),
    file.path(root, "vignettes"),
    file.path(root, "data-raw", "provenance"),
    file.path(root, "README.Rmd"),
    file.path(root, "README.md"),
    file.path(root, "NEWS.md")
  )
  files <- unlist(lapply(docs, function(path) {
    if (dir.exists(path)) {
      list.files(path, recursive = TRUE, full.names = TRUE)
    } else if (file.exists(path)) {
      path
    } else {
      character()
    }
  }))
  files <- files[grepl("\\.(R|Rd|Rmd|md|csv)$", files)]
  files <- files[basename(files) != "test-ternary-terminology.R"]
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  text_without_function_names <- gsub("plot_texture_triangle\\(\\)", "", text, fixed = FALSE)
  text_without_function_names <- gsub("plot_texture_ternary\\(\\)", "", text_without_function_names, fixed = FALSE)
  text_without_function_names <- gsub("plot_texture_triangle", "", text_without_function_names, fixed = TRUE)
  text_without_function_names <- gsub("plot_texture_ternary", "", text_without_function_names, fixed = TRUE)
  bad_ternary <- paste(c(
    paste("triangle", "plot"),
    paste("triangle", "plots"),
    paste("texture", "triangle", "plot"),
    paste("texture", "triangle", "plots")
  ), collapse = "|")
  legacy_shape_terms <- paste(c(
    paste("GRADISTAT", "triangle"),
    paste("USDA", "triangle")
  ), collapse = "|")

  expect_false(grepl(bad_ternary, text_without_function_names, ignore.case = TRUE))
  expect_false(grepl(legacy_shape_terms, text_without_function_names))
  expect_true(grepl("ternary plot", text_without_function_names, ignore.case = TRUE))

  rd <- paste(readLines(file.path(root, "man", "plot_texture_triangle.Rd"), warn = FALSE), collapse = "\n")
  expect_true(grepl("ternary plot", rd, ignore.case = TRUE))

  alias_rd <- paste(readLines(file.path(root, "man", "plot_texture_ternary.Rd"), warn = FALSE), collapse = "\n")
  expect_true(grepl("preferred", alias_rd, ignore.case = TRUE))
  expect_true(grepl("ternary plot", alias_rd, ignore.case = TRUE))
})
