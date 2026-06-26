test_that("GRADISTAT texture helper exists and remains internal", {
  ns <- asNamespace("grainsizeR")
  exports <- getNamespaceExports("grainsizeR")

  expect_true(exists(".classify_gradistat_texture_rules", envir = ns, inherits = FALSE))
  expect_false(any(grepl("gradistat_texture_rules|classify_gradistat", exports)))
})

gradistat_texture_rules_root <- function() {
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

test_that("GRADISTAT gravel-sand-mud boundary behavior is deterministic", {
  points <- data.frame(
    gravel = c(80, 30, 5, 0, 10, 10, 10),
    sand = c(10, 63, 85.5, 90, 81, 45, 10),
    mud = c(10, 7, 9.5, 10, 9, 45, 80),
    expected = c(
      "gravel", "sandy_gravel", "gravelly_sand", "sand",
      "gravelly_sand", "gravelly_muddy_sand", "gravelly_mud"
    )
  )

  result <- grainsizeR:::.classify_gradistat_texture_rules(points, basis = "gravel_sand_mud")

  expect_equal(result$texture_class_id, points$expected)
})

test_that("GRADISTAT sand-silt-clay boundary behavior is deterministic", {
  points <- data.frame(
    sand = c(90, 50, 10, 60, 60, 5, 5),
    silt = c(5, 34, 60, 26.666667, 12, 66, 20),
    clay = c(5, 16, 30, 13.333333, 28, 29, 75),
    expected = c("sand", "silty_sand", "sandy_silt", "silty_sand", "clayey_sand", "silt", "clay")
  )

  result <- grainsizeR:::.classify_gradistat_texture_rules(points, basis = "sand_silt_clay_no_gravel")

  expect_equal(result$texture_class_id, points$expected)
})

test_that("GRADISTAT internal helper rejects invalid inputs clearly", {
  expect_error(
    grainsizeR:::.classify_gradistat_texture_rules(
      data.frame(gravel = 10, sand = 40, mud = 40),
      basis = "gravel_sand_mud"
    ),
    "sum to approximately 100"
  )
  expect_error(
    grainsizeR:::.classify_gradistat_texture_rules(
      data.frame(sand = 50, silt = 25),
      basis = "sand_silt_clay_no_gravel"
    ),
    "requires columns"
  )
  expect_error(
    grainsizeR:::.classify_gradistat_texture_rules(
      data.frame(sand = 101, silt = -1, clay = 0),
      basis = "sand_silt_clay_no_gravel"
    ),
    "between 0 and 100"
  )
})

test_that("GRADISTAT texture rules add no runtime data objects", {
  root <- gradistat_texture_rules_root()
  data_files <- if (dir.exists(file.path(root, "data"))) {
    list.files(file.path(root, "data"), recursive = TRUE, full.names = FALSE)
  } else {
    character()
  }
  extdata_files <- list.files(
    file.path(root, "inst", "extdata"),
    recursive = TRUE,
    full.names = FALSE
  )
  forbidden <- "gradistat.*(classifier|polygon|texture.*triangle|rule)"

  expect_false(any(grepl(forbidden, data_files, ignore.case = TRUE)))
  expect_false(any(grepl(forbidden, extdata_files, ignore.case = TRUE)))
})
