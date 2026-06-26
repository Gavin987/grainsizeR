license_provenance_root <- function() {
  candidates <- c(
    file.path("..", "00_pkg_src", "grainsizeR"),
    file.path("..", "..", "00_pkg_src", "grainsizeR"),
    ".",
    file.path("..", "..")
  )
  roots <- candidates[file.exists(file.path(candidates, "DESCRIPTION"))]
  expect_gt(length(roots), 0)
  roots[1]
}

test_that("package uses MIT license metadata", {
  root <- license_provenance_root()
  desc <- read.dcf(file.path(root, "DESCRIPTION"))

  expect_identical(unname(desc[1, "License"]), "MIT + file LICENSE")
  expect_true(file.exists(file.path(root, "LICENSE")))

  license_text <- paste(readLines(file.path(root, "LICENSE"), warn = FALSE), collapse = "\n")
  expect_true(grepl("Ching-Sung G. Chang", license_text, fixed = TRUE))
})

test_that("README documents license and provenance policy", {
  root <- license_provenance_root()
  readme <- paste(readLines(file.path(root, "README.md"), warn = FALSE), collapse = "\n")

  expect_true(grepl("MIT License", readme, fixed = TRUE))
  expect_true(grepl("public provenance notes", readme, ignore.case = TRUE))
  expect_true(grepl("source boundaries", readme, ignore.case = TRUE))
  expect_false(grepl("official texture polygon datasets are bundled", readme, ignore.case = TRUE))
  expect_false(grepl("civil[- ]engineering classification modules", readme, ignore.case = TRUE))
})

test_that("public provenance note forbids copied package data", {
  root <- license_provenance_root()
  note <- paste(readLines(
    file.path(root, "data-raw", "provenance", "source-boundaries.md"),
    warn = FALSE
  ), collapse = "\n")

  expect_true(grepl("does not depend on `soiltexture`", note, fixed = TRUE))
  expect_true(grepl("does not copy G2Sd source code", note, fixed = TRUE))
  expect_true(grepl("VBA source code was not copied", note, fixed = TRUE))
})

test_that("license policy does not add unsupported runtime artifacts", {
  expect_false("export_gradistat_summary" %in% getNamespaceExports("grainsizeR"))

  data_files <- if (dir.exists("data")) {
    list.files("data", recursive = TRUE, full.names = FALSE)
  } else {
    character()
  }
  extdata_files <- list.files(file.path("inst", "extdata"), recursive = TRUE, full.names = FALSE)

  expect_false(any(grepl("polygon|coordinate|reconstruction", data_files, ignore.case = TRUE)))
  expect_false(any(grepl("polygon|coordinate|reconstruction", extdata_files, ignore.case = TRUE)))
})
