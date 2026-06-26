terminology_root <- function() {
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

read_text_file <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

strip_markdown_code <- function(text) {
  text <- gsub("```[\\s\\S]*?```", "", text, perl = TRUE)
  gsub("`[^`]*`", "", text, perl = TRUE)
}

prose_files_for_terminology <- function(root) {
  candidates <- list.files(
    root,
    pattern = "\\.(md|Rmd|Rd)$",
    recursive = TRUE,
    full.names = TRUE
  )
  candidates[!grepl(paste0(
    "\\.git|",
    "\\.Rcheck|",
    "packrat|",
    "renv"
  ), candidates)]
}

test_that("prose files do not contain GRADISTAT misspellings", {
  files <- prose_files_for_terminology(terminology_root())
  text <- paste(vapply(files, read_text_file, character(1)), collapse = "\n")
  bad_gradistat <- paste(c(
    paste0("\\b", "GRD", "ISTAT", "\\b"),
    paste0("\\b", "GRAD", "STAT", "\\b"),
    paste0("\\b", "Gradi", "stat", "\\b")
  ), collapse = "|")

  expect_false(grepl(bad_gradistat, text))
  expect_true(grepl("\\bGRADISTAT\\b", text))
})

test_that("prose files use G2Sd capitalization for prose references", {
  files <- prose_files_for_terminology(terminology_root())
  text <- paste(vapply(files, read_text_file, character(1)), collapse = "\n")
  prose_text <- strip_markdown_code(text)
  bad_g2sd <- paste(c(
    paste0("\\b", "G2", "SD", "\\b"),
    paste0("\\b", "G2", "sd", "\\b"),
    paste0("\\b", "g2", "sd", "\\b")
  ), collapse = "|")

  expect_true(grepl("\\bG2Sd\\b", prose_text))
  expect_false(grepl(bad_g2sd, prose_text))
})

test_that("public provenance files use approved software names", {
  root <- terminology_root()
  files <- list.files(
    file.path(root, "data-raw", "provenance"),
    pattern = "\\.(md|csv)$",
    recursive = TRUE,
    full.names = TRUE
  )
  text <- paste(vapply(files, read_text_file, character(1)), collapse = "\n")
  bad_gradistat <- paste(c(
    paste0("\\b", "Gradi", "stat", "\\b"),
    paste0("\\b", "GRAD", "STAT", "\\b"),
    paste0("\\b", "GRD", "ISTAT", "\\b")
  ), collapse = "|")
  bad_g2sd <- paste(c(
    paste0("\\b", "G2", "SD", "\\b"),
    paste0("\\b", "G2", "sd", "\\b")
  ), collapse = "|")

  expect_false(grepl(bad_gradistat, text))
  expect_false(grepl(bad_g2sd, text))
  expect_true(grepl("\\bGRADISTAT\\b", text))
  expect_true(grepl("\\bG2Sd\\b", text))
})
