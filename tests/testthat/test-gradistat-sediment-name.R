gradistat_sediment_name_test_root <- function() {
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

test_that("gs_gradistat_sediment_name is exported with required columns", {
  expect_true("gs_gradistat_sediment_name" %in% getNamespaceExports("grainsizeR"))
  result <- gs_gradistat_sediment_name(data.frame(gravel = 0, sand = 95, mud = 5))
  required <- c(
    "textural_group_class_id", "textural_group", "mini_texture_class_id",
    "mini_texture_class", "dominant_gravel_class", "dominant_sand_class",
    "dominant_silt_class", "sediment_name", "sediment_name_status",
    "sediment_name_method", "notes"
  )

  expect_true(all(required %in% names(result)))
  expect_equal(result$sediment_name, "sand")
  expect_equal(result$sediment_name_status, "missing_subclass_data")
})

test_that("gs_gradistat_sediment_name preserves row order for representative inputs", {
  input <- data.frame(
    candidate_id = c("sand", "silt", "gravelly_sand"),
    gravel = c(0, 0, 10),
    sand = c(95, 5, 85),
    mud = c(5, 95, 5),
    silt = c(3, 90, NA),
    clay = c(2, 5, NA),
    texture_class_id = c("sand", "silt", "gravelly_sand"),
    texture_class = c("sand", "silt", "gravelly sand"),
    ternary_basis = c(
      "gravel_sand_mud",
      "sand_silt_clay_no_gravel",
      "gravel_sand_mud"
    ),
    coarse_sand = c(100, NA, 100),
    medium_sand = c(0, NA, 0),
    coarse_silt = c(NA, 100, NA),
    medium_silt = c(NA, 0, NA)
  )

  result <- gs_gradistat_sediment_name(input)

  expect_equal(result$candidate_id, input$candidate_id)
  expect_equal(result$sediment_name, c("coarse sand", "coarse silt", "gravelly coarse sand"))
})

test_that("gs_gradistat_sediment_name handles ties deterministically", {
  input <- data.frame(
    sample_id = "tie",
    gravel = 0,
    sand = 95,
    mud = 5,
    coarse_sand = 50,
    medium_sand = 50
  )

  result <- gs_gradistat_sediment_name(input)

  expect_equal(result$dominant_sand_class, "coarse sand")
  expect_equal(result$sediment_name, "coarse sand")
  expect_equal(result$sediment_name_status, "resolved")
})

test_that("gs_gradistat_sediment_name rejects invalid inputs clearly", {
  expect_error(gs_gradistat_sediment_name("not data"), "`x` must be a data frame")
  expect_error(
    gs_gradistat_sediment_name(data.frame(gravel = 0, sand = 95, mud = 5, fine_sand = -1)),
    "subclass percentages"
  )
  expect_error(
    gs_gradistat_sediment_name(data.frame(gravel = 0, sand = 90, mud = 20)),
    "sum to approximately 100"
  )
})

test_that("gs_gradistat_sediment_name does not use USDA rules, soiltexture, or new dependencies", {
  root <- gradistat_sediment_name_test_root()
  text <- paste(readLines(file.path(root, "R", "gradistat-sediment-name.R"), warn = FALSE), collapse = "\n")
  deps <- read.dcf(file.path(root, "DESCRIPTION"))
  dependency_text <- paste(deps[, intersect(colnames(deps), c("Imports", "Depends", "Suggests"))], collapse = "\n")

  expect_false(grepl("usda|USDA", text))
  expect_false(grepl("soiltexture", text, ignore.case = TRUE))
  expect_false(grepl("soiltexture", dependency_text, ignore.case = TRUE))
})
