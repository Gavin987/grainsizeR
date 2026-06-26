find_usda_major_rules_root <- function() {
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

usda_major_rule_classes <- function() {
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

test_that("internal USDA major texture rule helper exists and is not exported", {
  root <- find_usda_major_rules_root()
  namespace <- loadNamespace("grainsizeR")

  expect_true(exists(".classify_usda_major_texture_rules", envir = namespace, inherits = FALSE))
  expect_true(exists(".usda_major_texture_rule_matches", envir = namespace, inherits = FALSE))
  expect_true(exists(".validate_usda_major_texture_input", envir = namespace, inherits = FALSE))

  namespace_text <- paste(readLines(file.path(root, "NAMESPACE"), warn = FALSE), collapse = "\n")
  expect_false(grepl("export\\(.*usda", namespace_text, ignore.case = TRUE))
})

test_that("internal USDA major texture helper classifies representative points", {
  classifier <- getFromNamespace(".classify_usda_major_texture_rules", "grainsizeR")
  points <- data.frame(
    class_id = usda_major_rule_classes(),
    sand = c(90, 82, 60, 40, 20, 10, 55, 35, 10, 50, 10, 20),
    silt = c(5, 8, 30, 40, 65, 85, 20, 30, 55, 10, 45, 20),
    clay = c(5, 10, 10, 20, 15, 5, 25, 35, 35, 40, 45, 60),
    stringsAsFactors = FALSE
  )

  classified <- classifier(points$sand, points$silt, points$clay)

  expect_equal(classified$class_id, points$class_id)
  expect_equal(classified$all_rule_matches, points$class_id)
  expect_true(all(classified$rule_status == "classified"))
  expect_false(any(classified$rule_conflict))
  expect_false(any(classified$rule_gap))
})

test_that("internal USDA major texture helper handles vectors and invalid rows", {
  classifier <- getFromNamespace(".classify_usda_major_texture_rules", "grainsizeR")
  classified <- classifier(
    sand = c(90, 82, NA_real_, 50),
    silt = c(5, 8, 50, 10),
    clay = c(5, 10, 50, 10)
  )

  expect_equal(nrow(classified), 4)
  expect_equal(classified$class_id[1:2], c("sand", "loamy_sand"))
  expect_equal(classified$rule_status[3:4], c("invalid", "invalid"))
  expect_true(is.na(classified$class_id[3]))
  expect_true(is.na(classified$class_id[4]))
})

test_that("internal USDA major texture helper closes the exact sand 45 clay-loam boundary", {
  classifier <- getFromNamespace(".classify_usda_major_texture_rules", "grainsizeR")
  clay_loam_edges <- classifier(
    sand = c(45, 45, 45),
    silt = c(28, 25, 21),
    clay = c(27, 30, 34)
  )
  sandy_clay_edges <- classifier(
    sand = c(45, 45),
    silt = c(20, 19),
    clay = c(35, 36)
  )

  expect_equal(clay_loam_edges$class_id, rep("clay_loam", 3))
  expect_equal(clay_loam_edges$rule_status, rep("classified", 3))
  expect_false(any(clay_loam_edges$rule_conflict | clay_loam_edges$rule_gap))

  expect_equal(sandy_clay_edges$class_id, rep("sandy_clay", 2))
  expect_equal(sandy_clay_edges$rule_status, rep("classified", 2))
  expect_false(any(sandy_clay_edges$rule_conflict | sandy_clay_edges$rule_gap))
})

test_that("USDA major texture helper does not implement deferred modifier subclasses", {
  classifier <- getFromNamespace(".classify_usda_major_texture_rules", "grainsizeR")
  classified <- classifier(
    sand = c(90, 82, 60),
    silt = c(5, 8, 30),
    clay = c(5, 10, 10)
  )
  deferred <- c(
    "coarse_sand",
    "fine_sand",
    "very_fine_sand",
    "coarse_sandy_loam",
    "fine_sandy_loam",
    "very_fine_sandy_loam"
  )

  expect_true(all(classified$class_id %in% usda_major_rule_classes()))
  expect_false(any(deferred %in% classified$class_id))
})

test_that("USDA major texture helper adds no runtime USDA data and no soiltexture calls", {
  root <- find_usda_major_rules_root()
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
  call_pattern <- "soiltexture::|library\\([\"']?soiltexture|require\\([\"']?soiltexture|requireNamespace\\([\"']soiltexture"
  expect_false(grepl(call_pattern, code_text, ignore.case = TRUE))
})
