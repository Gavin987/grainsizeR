find_texture_contract_root <- function() {
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

test_that("classify_texture export contract remains stable", {
  exports <- getNamespaceExports("grainsizeR")

  expect_true("classify_texture" %in% exports)
  expect_false(any(grepl("^\\.?(classify_)?usda", exports, ignore.case = TRUE)))
})

test_that("USDA rule classification returns documented columns and preserves input", {
  samples <- data.frame(
    sample_id = c("B", "A", "C"),
    site = c("north", "south", "west"),
    sand = c(40, 85, 20),
    silt = c(40, 10, 20),
    clay = c(20, 5, 60),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "usda", method = "rules")

  expect_equal(result$sample_id, samples$sample_id)
  expect_equal(result$site, samples$site)
  expect_equal(result$sand, samples$sand)
  expect_equal(result$silt, samples$silt)
  expect_equal(result$clay, samples$clay)
  expect_true(all(c(
    "texture_class_id", "texture_class", "classification_method", "rule_status",
    "all_rule_matches", "rule_conflict", "rule_gap"
  ) %in% names(result)))
  expect_equal(result$classification_method, rep("usda_major_rules", nrow(samples)))
  expect_equal(result$rule_status, rep("classified", nrow(samples)))
})

test_that("USDA public scheme returns canonical texture class columns", {
  samples <- data.frame(
    sand = c(85, 40, 20),
    silt = c(10, 40, 20),
    clay = c(5, 20, 60)
  )

  result <- classify_texture(samples, scheme = "usda", method = "rules")

  expect_true(all(c("texture_class_id", "texture_class") %in% names(result)))
  expect_equal(result$classification_method, rep("usda_major_rules", nrow(samples)))
})

test_that("USDA texture classification rejects pre-release scheme name", {
  samples <- data.frame(
    sand = 85,
    silt = 10,
    clay = 5
  )

  expect_error(
    classify_texture(samples, scheme = "usda_tt", method = "rules"),
    'scheme = "usda_tt"',
    fixed = TRUE
  )
})

test_that("GRADISTAT rule classification returns canonical texture class columns", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    gravel = c(0, 10, 40),
    sand = c(95, 80, 40),
    mud = c(5, 10, 20)
  )

  result <- classify_texture(
    samples,
    scheme = "gradistat",
    method = "rules",
    basis = "gravel_sand_mud"
  )

  expect_true(all(c("texture_class_id", "texture_class") %in% names(result)))
  expect_false(any(is.na(result$texture_class_id)))
})

test_that("USDA class IDs and labels remain stable and readable", {
  samples <- data.frame(
    sand = c(90, 82, 60, 40, 20, 10, 55, 35, 10, 50, 10, 20),
    silt = c(5, 8, 30, 40, 65, 85, 20, 30, 55, 10, 45, 20),
    clay = c(5, 10, 10, 20, 15, 5, 25, 35, 35, 40, 45, 60)
  )
  expected_ids <- c(
    "sand", "loamy_sand", "sandy_loam", "loam", "silt_loam", "silt",
    "sandy_clay_loam", "clay_loam", "silty_clay_loam",
    "sandy_clay", "silty_clay", "clay"
  )
  expected_labels <- c(
    "sand", "loamy sand", "sandy loam", "loam", "silt loam", "silt",
    "sandy clay loam", "clay loam", "silty clay loam",
    "sandy clay", "silty clay", "clay"
  )

  result <- classify_texture(samples, scheme = "usda", method = "rules")

  expect_equal(result$texture_class_id, expected_ids)
  expect_equal(result$texture_class, expected_labels)
  expect_true(all(grepl("^[a-z]+(_[a-z]+)*$", result$texture_class_id)))
})

test_that("USDA rules reject invalid sums without silent normalization", {
  expect_error(
    classify_texture(
      data.frame(sand = 85, silt = 10, clay = 4),
      scheme = "usda",
      method = "rules"
    ),
    "sum to approximately 100"
  )
})

test_that("method dispatch is explicit and stable", {
  samples <- data.frame(
    sand = c(85, 40, 20),
    silt = c(10, 40, 20),
    clay = c(5, 20, 60)
  )

  rules <- classify_texture(samples, scheme = "usda", method = "rules")
  auto <- classify_texture(samples, scheme = "usda", method = "auto")

  expect_equal(auto$texture_class_id, rules$texture_class_id)
  expect_equal(auto$classification_method, rules$classification_method)
  expect_error(
    classify_texture(samples, scheme = "isss", method = "auto"),
    "`scheme` must be one of"
  )
  expect_error(
    classify_texture(samples, scheme = "usda", method = "polygon"),
    "No built-in texture polygon dataset is bundled"
  )
})

test_that("polygon method uses canonical texture class output names", {
  result <- classify_texture(
    fine_texture_gsd(),
    texture_polygons = test_texture_polygons(),
    scheme = "test_triangle",
    method = "polygon"
  )

  expect_true("texture_class_id" %in% names(result))
  expect_true("texture_class" %in% names(result))
  expect_false("class_id" %in% names(result))
  expect_false("class_name" %in% names(result))
  expect_false("classification_method" %in% names(result))
  expect_true(all(c("resolved", "ambiguous", "left", "right", "top", "x", "y") %in% names(result)))
  expect_equal(result$texture_class_id, c("all", "all"))
})

test_that("USDA public API adds no runtime data object or soiltexture calls", {
  root <- find_texture_contract_root()
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
  forbidden_data <- "usda.*(classifier|polygon|texture.*triangle|coordinate|rule)"
  expect_false(any(grepl(forbidden_data, data_files, ignore.case = TRUE)))
  expect_false(any(grepl(forbidden_data, extdata_files, ignore.case = TRUE)))

  code_files <- c(
    list.files(file.path(root, "R"), pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  )
  code_text <- paste(unlist(lapply(code_files, readLines, warn = FALSE)), collapse = "\n")
  call_pattern <- paste0(
    "soiltexture", "::|library\\([\"']?", "soiltexture",
    "|require\\([\"']?", "soiltexture",
    "|requireNamespace\\([\"']?", "soiltexture"
  )
  expect_false(grepl(call_pattern, code_text, ignore.case = TRUE))
})

test_that("USDA rule output does not include sand-size modifier subclasses", {
  result <- classify_texture(
    data.frame(sand = c(85, 60), silt = c(10, 30), clay = c(5, 10)),
    scheme = "usda",
    method = "rules"
  )
  deferred <- c(
    "coarse_sand", "fine_sand", "very_fine_sand",
    "coarse_sandy_loam", "fine_sandy_loam", "very_fine_sandy_loam"
  )

  expect_false(any(deferred %in% names(result)))
  expect_false(any(result$texture_class_id %in% deferred))
  expect_false(any(result$texture_class %in% gsub("_", " ", deferred)))
})
