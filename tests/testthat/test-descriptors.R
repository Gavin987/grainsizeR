descriptor_test_root <- function() {
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

descriptor_test_gsd <- function() {
  as_gsd_tbl(
    data.frame(
      sample_id = rep("A", 6),
      size_mm = c(4, 2, 1, 0.5, 0.25, 0.125),
      retained = c(5, 10, 20, 30, 25, 10)
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
}

test_that("GRADISTAT-style descriptor functions are exported", {
  exports <- getNamespaceExports("grainsizeR")

  expect_true("gs_describe_parameters" %in% exports)
  expect_true("gs_size_terms" %in% exports)
})

test_that("size terms classify representative values", {
  expect_equal(gs_size_terms(c(2.5, 0.5, -3), unit = "phi"), c("fine sand", "coarse sand", "pebble"))
  expect_equal(gs_size_terms(c(0.25, 0.004, 100), unit = "mm"), c("fine sand", "very fine silt", "cobble"))
  expect_equal(gs_size_terms(c(250, 4), unit = "um"), c("fine sand", "very fine silt"))
})

test_that("sorting, skewness, and kurtosis descriptors classify representative values", {
  x <- data.frame(
    sample_id = paste0("s", 1:3),
    mean_fw_phi = c(2.5, 1.5, 0.5),
    sorting_fw_phi = c(0.3, 1.2, 4.2),
    skewness_fw = c(-0.2, 0, 0.2),
    kurtosis_fw = c(0.8, 1.0, 1.6)
  )

  result <- gs_describe_parameters(x, method = "folk_ward")

  expect_equal(result$sorting_description, c("very well sorted", "poorly sorted", "extremely poorly sorted"))
  expect_equal(result$skewness_description, c("coarse skewed", "near symmetrical", "fine skewed"))
  expect_equal(result$kurtosis_description, c("platykurtic", "mesokurtic", "very leptokurtic"))
  expect_equal(result$description_status, rep("described", 3))
})

test_that("logarithmic moment descriptors use moment columns", {
  x <- data.frame(
    sample_id = "A",
    mean_moment_phi = 2.5,
    sd_moment_phi = 1.2,
    skewness_moment = -0.2,
    kurtosis_moment = 1.0
  )

  result <- gs_describe_parameters(x, method = "logarithmic_moments")

  expect_equal(result$mean_description, "fine sand")
  expect_equal(result$sorting_description, "poorly sorted")
  expect_equal(result$description_method, "logarithmic_moments")
  expect_equal(result$description_status, "described")
})

test_that("missing descriptor inputs return documented status", {
  result <- gs_describe_parameters(data.frame(sample_id = "A", mean_fw_phi = 2.5))

  expect_equal(result$description_status, "missing_required_values")
  expect_true(is.na(result$mean_description))
})

test_that("unsupported explicit descriptor method returns documented status", {
  result <- gs_describe_parameters(
    data.frame(
      sample_id = "A",
      mean_moment_phi = 2.5,
      sd_moment_phi = 1.2,
      skewness_moment = -0.2,
      kurtosis_moment = 1.0
    ),
    method = "folk_ward"
  )

  expect_equal(result$description_status, "unsupported_method")
  expect_equal(result$description_method, "folk_ward")
})

test_that("gs_parameters can include descriptor columns", {
  result <- suppressWarnings(gs_parameters(
    descriptor_test_gsd(),
    parameters = "descriptors",
    extrapolate = "warn_linear"
  ))

  expect_true(all(c(
    "mean_description", "sorting_description", "skewness_description",
    "kurtosis_description", "description_method", "description_status"
  ) %in% names(result)))
  expect_equal(result$description_status, "described")
})

test_that("descriptor support adds no package dependency", {
  description <- read.dcf(file.path(descriptor_test_root(), "DESCRIPTION"))
  dependency_fields <- paste(description[, intersect(colnames(description), c("Depends", "Imports", "Suggests"))], collapse = "\n")
  expect_false(grepl("soiltexture", dependency_fields, ignore.case = TRUE))
})
