public_repo_root <- function() {
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

read_public_repo_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

read_public_hygiene_text <- function(path) {
  text <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (basename(path) == "DESCRIPTION") {
    text <- text[!grepl("^Packaged:", text)]
  }
  paste(text, collapse = "\n")
}

test_that("public repository metadata and installation guidance are clean", {
  root <- public_repo_root()
  readme <- read_public_repo_text(file.path(root, "README.md"))
  desc <- read.dcf(file.path(root, "DESCRIPTION"))[1, ]
  license <- read_public_repo_text(file.path(root, "LICENSE"))

  expect_true(grepl("install.packages(\"remotes\")", readme, fixed = TRUE))
  expect_true(grepl("remotes::install_github(\"Gavin987/grainsizeR\")", readme, fixed = TRUE))
  expect_true(grepl("Ching-Sung G.", desc[["Authors@R"]], fixed = TRUE))
  expect_true(grepl("family = \"Chang\"", desc[["Authors@R"]], fixed = TRUE))
  expect_true(grepl("cschang.bt10@nycu.edu.tw", desc[["Authors@R"]], fixed = TRUE))
  expect_equal(unname(desc[["License"]]), "MIT + file LICENSE")
  expect_true(grepl("Ching-Sung G. Chang", license, fixed = TRUE))
})

test_that("public-facing files do not expose local paths or internal phase labels", {
  root <- public_repo_root()
  files <- c(
    file.path(root, "README.Rmd"),
    file.path(root, "README.md"),
    file.path(root, "NEWS.md"),
    file.path(root, "DESCRIPTION"),
    file.path(root, "CONTRIBUTING.md"),
    file.path(root, "CODE_OF_CONDUCT.md"),
    file.path(root, "SECURITY.md"),
    file.path(root, "CITATION.cff"),
    file.path(root, ".github", "ISSUE_TEMPLATE", "bug_report.md"),
    file.path(root, ".github", "ISSUE_TEMPLATE", "feature_request.md"),
    file.path(root, ".github", "PULL_REQUEST_TEMPLATE.md"),
    list.files(file.path(root, "vignettes"), pattern = "\\.Rmd$", full.names = TRUE),
    list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE),
    list.files(file.path(root, "man"), pattern = "\\.Rd$", full.names = TRUE)
  )
  files <- files[file.exists(files)]
  text <- paste(vapply(files, read_public_hygiene_text, character(1)), collapse = "\n")
  text_without_function_names <- gsub("plot_texture_triangle\\(\\)", "", text)
  text_without_function_names <- gsub("plot_texture_triangle", "", text_without_function_names, fixed = TRUE)
  internal_terms <- paste(c(
    paste("Phase", "[0-9]+"),
    paste0("Phase", "[0-9]+"),
    paste("Co", "dex", sep = ""),
    paste("sta", "ged", sep = ""),
    paste("ready", "to", "push", "to", "github", sep = "_"),
    paste("ready", "for", "public", "github", "preparation", sep = "_")
  ), collapse = "|")
  bad_ternary <- paste(c(
    paste("triangle", "plot"),
    paste("triangle", "plots"),
    paste("texture", "triangle", "plot"),
    paste("texture", "triangle", "plots")
  ), collapse = "|")
  bad_gradistat <- paste(c(
    paste0("\\b", "GRD", "ISTAT", "\\b"),
    paste0("\\b", "GRAD", "STAT", "\\b"),
    paste0("\\b", "Gradi", "stat", "\\b")
  ), collapse = "|")
  bad_g2sd <- paste(c(
    paste0("\\b", "G2", "SD", "\\b"),
    paste0("\\b", "G2", "sd", "\\b")
  ), collapse = "|")

  expect_false(grepl("C:/Users|C:\\\\Users|/mnt/data|/tmp/|/home/|DevProjects", text))
  expect_false(grepl(internal_terms, text))
  expect_false(grepl(bad_ternary, text_without_function_names, ignore.case = TRUE))
  expect_true(grepl("ternary plot", text, ignore.case = TRUE))
  expect_false(grepl(bad_gradistat, text))
  expect_false(grepl(bad_g2sd, text))
})

test_that("source-boundary and dependency hygiene are enforced", {
  root <- public_repo_root()
  desc <- read_public_repo_text(file.path(root, "DESCRIPTION"))
  r_files <- list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE)
  r_text <- paste(vapply(r_files, read_public_repo_text, character(1)), collapse = "\n")
  provenance <- read_public_repo_text(file.path(root, "data-raw", "provenance", "source-boundaries.md"))
  forbidden <- "soiltexture"
  call_pattern <- paste0(
    "\\b", forbidden, "::|library\\(", forbidden,
    "\\)|require\\(", forbidden, "\\)"
  )

  expect_false(grepl("\\bsoiltexture\\b", desc, ignore.case = TRUE))
  expect_false(grepl(call_pattern, r_text, ignore.case = TRUE))
  expect_true(grepl("does not copy G2Sd source code", provenance, fixed = TRUE))
  expect_true(grepl("does not depend on `soiltexture`", provenance, fixed = TRUE))
  expect_true(grepl("VBA source code was not copied", provenance, fixed = TRUE))
})

test_that("no external binary reference files are bundled", {
  root <- public_repo_root()
  candidates <- list.files(
    root,
    pattern = "\\.(xlsm|xlsx|pdf|png|jpg|jpeg|gif|tiff|bmp|zip)$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )
  candidates <- candidates[!grepl("\\.git|\\.Rcheck|/doc/|/Meta/|\\\\doc\\\\|\\\\Meta\\\\", candidates)]
  allowed <- file.path(root, c(
    "man/figures/readme-wide-distribution.png",
    "man/figures/readme-wide-cumulative.png",
    "man/figures/readme-wide-fractions.png",
    "man/figures/readme-gradistat-ternary.png",
    "man/figures/readme-usda-ternary.png"
  ))
  candidates <- setdiff(normalizePath(candidates, winslash = "/", mustWork = FALSE), normalizePath(allowed, winslash = "/", mustWork = FALSE))

  expect_equal(candidates, character())
})
