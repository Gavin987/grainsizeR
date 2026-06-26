quality_test_root <- function() {
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

quality_test_gsd <- function(fine_pan = 6) {
  as_gsd_tbl(
    data.frame(
      sample_id = rep("A", 5),
      size_mm = c(2, 1, 0.5, 0.25, 0.125),
      retained = c(10, 20, 30, 40 - fine_pan, fine_pan)
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
}

test_that("gs_quality_flags is exported", {
  expect_true("gs_quality_flags" %in% getNamespaceExports("grainsizeR"))
})

test_that("quality flags return required columns and not-evaluated sediment loss", {
  result <- gs_quality_flags(quality_test_gsd())
  required <- c("sample_id", "quality_flag", "quality_status", "quality_value", "quality_threshold", "quality_message")
  loss <- result[result$quality_flag == "sediment_loss", ]

  expect_true(all(required %in% names(result)))
  expect_equal(loss$quality_status, "not_evaluated")
})

test_that("sediment loss greater than two percent is flagged", {
  result <- gs_quality_flags(quality_test_gsd(), sediment_loss_percent = 3)
  loss <- result[result$quality_flag == "sediment_loss", ]

  expect_equal(loss$quality_status, "warning")
  expect_match(loss$quality_message, "exceeds")
})

test_that("open fine tail and fine pan fraction flags are advisory", {
  result <- gs_quality_flags(quality_test_gsd(fine_pan = 6))
  open <- result[result$quality_flag == "open_fine_tail", ]
  pan <- result[result$quality_flag == "fine_pan_fraction", ]

  expect_equal(open$quality_status, "needs_additional_analysis")
  expect_equal(pan$quality_status, "warning")
})

test_that("fine pan information threshold is distinguished from warning threshold", {
  result <- gs_quality_flags(quality_test_gsd(fine_pan = 2))
  pan <- result[result$quality_flag == "fine_pan_fraction", ]

  expect_equal(pan$quality_status, "needs_additional_analysis")
})

test_that("gs_parameters can include quality columns", {
  result <- gs_parameters(
    quality_test_gsd(),
    parameters = "quality",
    sediment_loss_percent = 3
  )

  expect_true(all(c(
    "sediment_loss_quality_status",
    "open_fine_tail_quality_status",
    "fine_pan_fraction_quality_status",
    "quality_overall_status"
  ) %in% names(result)))
  expect_equal(result$sediment_loss_quality_status, "warning")
})

test_that("quality support adds no package dependency", {
  description <- read.dcf(file.path(quality_test_root(), "DESCRIPTION"))
  dependency_fields <- paste(description[, intersect(colnames(description), c("Depends", "Imports", "Suggests"))], collapse = "\n")
  expect_false(grepl("soiltexture", dependency_fields, ignore.case = TRUE))
})
