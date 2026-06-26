public_usda_major_rule_classes <- function() {
  c(
    "sand",
    "loamy_sand",
    "sandy_loam",
    "loam",
    "silt_loam",
    "silt",
    "sandy_clay_loam",
    "clay_loam",
    "silty_clay_loam",
    "sandy_clay",
    "silty_clay",
    "clay"
  )
}

find_public_usda_rules_root <- function() {
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

test_that("classify_texture exposes USDA major rules for sand, silt, and clay data frames", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    sand = c(90, 40, 20),
    silt = c(5, 40, 20),
    clay = c(5, 20, 60),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "usda_tt", method = "rules")

  expect_equal(result$sample_id, samples$sample_id)
  expect_equal(result$texture_class_id, c("sand", "loam", "clay"))
  expect_equal(result$texture_class, c("sand", "loam", "clay"))
  expect_equal(result$classification_method, rep("usda_major_rules", 3))
  expect_equal(result$rule_status, rep("classified", 3))
  expect_true(all(c(
    "texture_class_id", "texture_class", "classification_method", "rule_status",
    "all_rule_matches", "rule_conflict", "rule_gap"
  ) %in% names(result)))
})

test_that("classify_texture auto-selects USDA rules when no polygons are supplied", {
  samples <- data.frame(
    sample_id = c("A", "B"),
    sand = c(82, 10),
    silt = c(8, 85),
    clay = c(10, 5),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "usda_tt")

  expect_equal(result$texture_class_id, c("loamy_sand", "silt"))
  expect_equal(result$classification_method, rep("usda_major_rules", 2))
})

test_that("classify_texture supports ternary columns for USDA rules with documented mapping", {
  samples <- data.frame(
    sample_id = c("A", "B"),
    left = c(60, 35),
    right = c(30, 30),
    top = c(10, 35),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "usda_tt", method = "rules")

  expect_equal(result$sand, samples$left)
  expect_equal(result$silt, samples$right)
  expect_equal(result$clay, samples$top)
  expect_equal(result$texture_class_id, c("sandy_loam", "clay_loam"))
})

test_that("classify_texture classifies representative points for all USDA major classes", {
  points <- data.frame(
    class_id = public_usda_major_rule_classes(),
    sand = c(90, 82, 60, 40, 20, 10, 55, 35, 10, 50, 10, 20),
    silt = c(5, 8, 30, 40, 65, 85, 20, 30, 55, 10, 45, 20),
    clay = c(5, 10, 10, 20, 15, 5, 25, 35, 35, 40, 45, 60),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(points, scheme = "usda_tt", method = "rules")

  expect_equal(result$texture_class_id, points$class_id)
  expect_equal(result$all_rule_matches, points$class_id)
  expect_false(any(result$rule_conflict))
  expect_false(any(result$rule_gap))
})

test_that("classify_texture preserves validated USDA boundary decisions", {
  points <- data.frame(
    case_id = c(
      "sand_45_clay_27",
      "sand_45_clay_34",
      "sand_45_clay_35",
      "silt_80_clay_below_12",
      "silt_80_clay_12"
    ),
    sand = c(45, 45, 45, 10, 8),
    silt = c(28, 21, 20, 80, 80),
    clay = c(27, 34, 35, 10, 12),
    expected_class_id = c("clay_loam", "clay_loam", "sandy_clay", "silt", "silt_loam"),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(points, scheme = "usda_tt", method = "rules")

  expect_equal(result$case_id, points$case_id)
  expect_equal(result$texture_class_id, points$expected_class_id)
  expect_equal(result$rule_status, rep("classified", nrow(points)))
  expect_false(any(result$rule_conflict | result$rule_gap))
}
)

test_that("classify_texture rejects invalid USDA rule inputs clearly", {
  expect_error(
    classify_texture(
      data.frame(sand = 50, silt = 20, clay = 20),
      scheme = "usda_tt",
      method = "rules"
    ),
    "sum to approximately 100"
  )
  expect_error(
    classify_texture(
      data.frame(sand = 101, silt = -1, clay = 0),
      scheme = "usda_tt",
      method = "rules"
    ),
    "between 0 and 100"
  )
})

test_that("classify_texture reports missing non-USDA built-in polygons clearly", {
  expect_error(
    classify_texture(data.frame(sand = 40, silt = 40, clay = 20), scheme = "isss"),
    "No built-in texture polygon dataset is bundled"
  )
})

test_that("classify_texture keeps polygon classification available", {
  result <- classify_texture(
    fine_texture_gsd(),
    scheme = "test_triangle",
    method = "polygon",
    texture_polygons = test_texture_polygons()
  )

  expect_equal(result$class_name, c("All triangle", "All triangle"))
  expect_true(all(result$resolved))
  expect_false(any(result$ambiguous))
})

test_that("classify_texture selects polygon classification when polygons are supplied with auto", {
  result <- classify_texture(
    fine_texture_gsd(),
    scheme = "test_triangle",
    method = "auto",
    texture_polygons = test_texture_polygons()
  )

  expect_equal(result$class_id, c("all", "all"))
  expect_false("texture_class_id" %in% names(result))
})

test_that("USDA public path does not export helpers or add runtime data", {
  root <- find_public_usda_rules_root()
  exports <- getNamespaceExports("grainsizeR")
  expect_false(any(grepl("^\\.?(classify_)?usda", exports, ignore.case = TRUE)))

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
  forbidden <- "usda.*(classifier|polygon|texture.*triangle|coordinate|rule)"
  expect_false(any(grepl(forbidden, data_files, ignore.case = TRUE)))
  expect_false(any(grepl(forbidden, extdata_files, ignore.case = TRUE)))
})

test_that("USDA public path does not call soiltexture or return modifier subclasses", {
  root <- find_public_usda_rules_root()
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

  result <- classify_texture(
    data.frame(sand = c(90, 82, 60), silt = c(5, 8, 30), clay = c(5, 10, 10)),
    scheme = "usda_tt",
    method = "rules"
  )
  deferred <- c(
    "coarse_sand", "fine_sand", "very_fine_sand",
    "coarse_sandy_loam", "fine_sandy_loam", "very_fine_sandy_loam"
  )
  expect_false(any(deferred %in% names(result)))
  expect_false(any(result$texture_class_id %in% deferred))
})
