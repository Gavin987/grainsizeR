release_metadata_package_root <- function() {
  candidates <- c(
    file.path("..", "00_pkg_src", "grainsizeR"),
    file.path("..", "..", "00_pkg_src", "grainsizeR"),
    ".",
    file.path("..", "..")
  )
  roots <- candidates[
    file.exists(file.path(candidates, "DESCRIPTION"))
  ]
  expect_gt(length(roots), 0)
  roots[1]
}

release_metadata_repo_root <- function() {
  candidates <- c(
    file.path("..", "00_pkg_src", "grainsizeR"),
    file.path("..", "..", "00_pkg_src", "grainsizeR"),
    ".",
    file.path("..", "..")
  )
  roots <- candidates[
    file.exists(file.path(candidates, ".github", "workflows", "R-CMD-check.yaml")) &
      file.exists(file.path(candidates, ".github", "workflows", "pkgdown.yaml"))
  ]
  roots[1]
}

test_that("release documentation and templates exist", {
  root <- release_metadata_repo_root()
  if (is.na(root)) {
    skip("Repository-only GitHub metadata is excluded from the package source tarball.")
  }

  expect_true(file.exists(file.path(root, "RELEASE.md")))
  expect_true(file.exists(file.path(root, ".github", "ISSUE_TEMPLATE", "bug_report.md")))
  expect_true(file.exists(file.path(root, ".github", "ISSUE_TEMPLATE", "feature_request.md")))
  expect_true(file.exists(file.path(root, ".github", "PULL_REQUEST_TEMPLATE.md")))
})

test_that("README contains development GitHub installation guidance", {
  root <- release_metadata_package_root()
  readme <- paste(readLines(file.path(root, "README.md"), warn = FALSE), collapse = "\n")

  expect_true(grepl("install.packages(\"remotes\")", readme, fixed = TRUE))
  expect_true(grepl("remotes::install_github(\"Gavin987/grainsizeR\")", readme, fixed = TRUE))
  expect_true(grepl("library(grainsizeR)", readme, fixed = TRUE))
  placeholder_owner <- paste0("<", "OWNER", ">/")
  expect_false(grepl(placeholder_owner, readme, fixed = TRUE))
  expect_false(grepl("official built-in texture polygon datasets are bundled", readme, ignore.case = TRUE))
  expect_false(grepl("civil[- ]engineering classification modules", readme, ignore.case = TRUE))
})

test_that("release metadata files are present and version is valid", {
  root <- release_metadata_package_root()
  desc <- read.dcf(file.path(root, "DESCRIPTION"))

  expect_identical(unname(desc[1, "Package"]), "grainsizeR")
  expect_s3_class(package_version(desc[1, "Version"]), "package_version")
  expect_true(grepl("https://github.com/Gavin987/grainsizeR", desc[1, "URL"], fixed = TRUE))
  expect_true(grepl("https://github.com/Gavin987/grainsizeR/issues", desc[1, "BugReports"], fixed = TRUE))
  expect_true(grepl("cschang.bt10@nycu.edu.tw", paste(readLines(file.path(root, "DESCRIPTION")), collapse = "\n"), fixed = TRUE))
})

test_that("release notes describe first GitHub push without extra release material", {
  root <- release_metadata_package_root()
  release <- paste(readLines(file.path(root, "RELEASE.md"), warn = FALSE), collapse = "\n")

  expect_true(grepl("First GitHub Push Checklist", release, fixed = TRUE))
  expect_true(
    grepl("git remote add origin https://github.com/Gavin987/grainsizeR.git", release, fixed = TRUE) ||
      grepl("git remote set-url origin https://github.com/Gavin987/grainsizeR.git", release, fixed = TRUE)
  )
  expect_true(grepl("devtools::install_github(\"Gavin987/grainsizeR\")", release, fixed = TRUE))
  expect_false(file.exists(file.path(root, paste0("cran-", "comments.md"))))
})

test_that("pkgdown configuration exists in the repository source", {
  root <- release_metadata_repo_root()
  if (is.na(root)) {
    skip("Repository-only pkgdown metadata is excluded from the package source tarball.")
  }

  expect_true(file.exists(file.path(root, "_pkgdown.yml")))
})

test_that("GitHub workflow files exist in the repository source", {
  root <- release_metadata_repo_root()
  if (is.na(root)) {
    skip("Repository-only GitHub workflow files are excluded from the package source tarball.")
  }

  expect_true(file.exists(file.path(root, ".github", "workflows", "R-CMD-check.yaml")))
  expect_true(file.exists(file.path(root, ".github", "workflows", "pkgdown.yaml")))
})

test_that("NEWS records pre-release preparation", {
  root <- release_metadata_package_root()
  news <- paste(readLines(file.path(root, "NEWS.md"), warn = FALSE), collapse = "\n")

  expect_true(grepl("Prepared GitHub pre-release documentation and repository templates", news, fixed = TRUE))
})

test_that("release metadata does not add unsupported runtime artifacts", {
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
