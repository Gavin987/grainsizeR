mode_test_gsd <- function() {
  as_gsd_tbl(
    data.frame(
      sample_id = rep(c("A", "B"), each = 6),
      size_mm = rep(c(4, 2, 1, 0.5, 0.25, 0.125), 2),
      retained = c(
        5, 40, 10, 30, 10, 5,
        5, 25, 25, 20, 20, 5
      )
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
}

mode_test_root <- function() {
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

test_that("gs_modes is exported", {
  expect_true("gs_modes" %in% getNamespaceExports("grainsizeR"))
})

test_that("gs_modes returns up to three ranked modes per sample", {
  result <- gs_modes(mode_test_gsd())
  sample_a <- result[result$sample_id == "A", ]

  expect_equal(nrow(result), 6)
  expect_equal(sample_a$mode_rank, 1:3)
  expect_equal(sample_a$mode_percent, c(40, 30, 10))
  expect_equal(sample_a$sample_modality[1], "bimodal")
  expect_true(all(c(
    "mode_size_mm", "mode_size_um", "mode_phi",
    "mode_class_lower_mm", "mode_class_upper_mm",
    "mode_percent", "mode_class_label", "is_open_interval", "mode_status"
  ) %in% names(result)))
})

test_that("gs_modes preserves sample identifiers and deterministic tie order", {
  result <- gs_modes(mode_test_gsd())
  sample_b <- result[result$sample_id == "B", ]

  expect_equal(unique(result$sample_id), c("A", "B"))
  expect_equal(sample_b$mode_percent, c(25, 25, 20))
  expect_equal(sample_b$mode_rank, 1:3)
  expect_equal(sample_b$mode_status[1:2], c("tied", "tied"))
  expect_equal(sample_b$sample_modality[1], "flat_or_tied")
})

test_that("gs_modes marks open-ended modal classes without midpoint fabrication", {
  gsd <- as_gsd_tbl(
    data.frame(
      sample_id = rep("A", 5),
      size_mm = c(4, 2, 1, 0.5, 0.25),
      retained = c(55, 20, 10, 10, 5)
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
  result <- gs_modes(gsd)

  expect_true(result$is_open_interval[1])
  expect_equal(result$mode_status[1], "open_interval")
  expect_true(is.na(result$mode_size_mm[1]))
  expect_true(is.na(result$mode_size_um[1]))
  expect_true(is.na(result$mode_phi[1]))
})

test_that("gs_modes can return a different number of modes", {
  result <- gs_modes(mode_test_gsd(), n_modes = 2)

  expect_equal(nrow(result), 4)
  expect_equal(sort(unique(result$mode_rank)), 1:2)
})

test_that("gs_parameters can include modes without changing row count", {
  result <- gs_parameters(mode_test_gsd(), parameters = "modes")

  expect_equal(nrow(result), 2)
  expect_true(all(c(
    "sample_modality", "mode1_size_mm", "mode1_percent", "mode1_status",
    "mode2_size_mm", "mode2_percent", "mode2_status",
    "mode3_size_mm", "mode3_percent", "mode3_status"
  ) %in% names(result)))
})

test_that("mode support adds no package dependency", {
  description <- read.dcf(file.path(mode_test_root(), "DESCRIPTION"))
  dependency_fields <- paste(description[, intersect(colnames(description), c("Depends", "Imports", "Suggests"))], collapse = "\n")
  expect_false(grepl("soiltexture", dependency_fields, ignore.case = TRUE))
})
