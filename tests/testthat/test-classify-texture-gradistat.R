test_that("classify_texture supports GRADISTAT gravel-sand-mud rules", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    gravel = c(0, 10, 40),
    sand = c(95, 80, 40),
    mud = c(5, 10, 20),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "gradistat", method = "rules", basis = "gravel_sand_mud")

  expect_equal(result$sample_id, samples$sample_id)
  expect_equal(result$texture_class_id, c("sand", "gravelly_muddy_sand", "muddy_sandy_gravel"))
  expect_equal(result$classification_method, rep("gradistat_texture_rules", 3))
  expect_equal(result$classification_status, rep("classified", 3))
  expect_equal(result$ternary_basis, rep("gravel_sand_mud", 3))
  expect_true(all(c(
    "texture_class_id", "texture_class", "classification_method",
    "classification_status", "ternary_basis", "notes", "sand_mud_ratio"
  ) %in% names(result)))
})

test_that("classify_texture supports GRADISTAT sand-silt-clay no-gravel rules", {
  samples <- data.frame(
    sample_id = c("A", "B", "C"),
    sand = c(95, 60, 20),
    silt = c(3, 30, 60),
    clay = c(2, 10, 20),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(
    samples,
    scheme = "gradistat",
    method = "rules",
    basis = "sand_silt_clay_no_gravel"
  )

  expect_equal(result$sample_id, samples$sample_id)
  expect_equal(result$texture_class_id, c("sand", "silty_sand", "sandy_silt"))
  expect_equal(result$classification_status, rep("classified", 3))
  expect_true("silt_clay_ratio" %in% names(result))
})

test_that("classify_texture auto-selects GRADISTAT rules without polygons", {
  samples <- data.frame(
    sample_id = c("A", "B"),
    gravel = c(3, 0),
    sand = c(60, 20),
    mud = c(37, 80),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "gradistat", method = "auto", basis = "gravel_sand_mud")

  expect_equal(result$texture_class_id, c("slightly_gravelly_muddy_sand", "sandy_mud"))
  expect_equal(result$classification_method, rep("gradistat_texture_rules", 2))
})

test_that("GRADISTAT no-gravel and slightly gravelly split follows workbook-derived rules", {
  samples <- data.frame(
    sample_id = c("no_gravel", "trace_visual", "five_percent"),
    gravel = c(0, 1.5, 5),
    sand = c(60, 59.1, 57),
    mud = c(40, 39.4, 38),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(samples, scheme = "gradistat", method = "rules", basis = "gravel_sand_mud")

  expect_equal(result$texture_class_id, c("muddy_sand", "slightly_gravelly_muddy_sand", "gravelly_muddy_sand"))
})

test_that("classify_texture can append GRADISTAT sediment-name fields", {
  samples <- data.frame(
    sample_id = c("A", "B"),
    gravel = c(0, 10),
    sand = c(95, 82),
    mud = c(5, 8),
    fine_sand = c(80, 10),
    very_coarse_sand = c(20, 90),
    stringsAsFactors = FALSE
  )

  result <- classify_texture(
    samples,
    scheme = "gradistat",
    method = "rules",
    basis = "gravel_sand_mud",
    include_sediment_name = TRUE
  )

  expect_true(all(c("sediment_name", "sediment_name_status", "sediment_name_method") %in% names(result)))
  expect_equal(result$sediment_name, c("fine sand", "gravelly very coarse sand"))
  expect_equal(result$sediment_name_status, rep("resolved", 2))
})

test_that("classify_texture returns partial GRADISTAT sediment names without subclasses", {
  result <- classify_texture(
    data.frame(sample_id = "A", gravel = 0, sand = 95, mud = 5),
    scheme = "gradistat",
    method = "rules",
    basis = "gravel_sand_mud",
    include_sediment_name = TRUE
  )

  expect_equal(result$sediment_name, "sand")
  expect_equal(result$sediment_name_status, "missing_subclass_data")
})

test_that("include_sediment_name does not change USDA rule output", {
  base <- classify_texture(
    data.frame(sand = 90, silt = 5, clay = 5),
    scheme = "usda_tt",
    method = "rules"
  )
  with_arg <- classify_texture(
    data.frame(sand = 90, silt = 5, clay = 5),
    scheme = "usda_tt",
    method = "rules",
    include_sediment_name = TRUE
  )

  expect_equal(names(with_arg), names(base))
  expect_false("sediment_name" %in% names(with_arg))
})

test_that("classify_texture rejects invalid GRADISTAT public inputs clearly", {
  expect_error(
    classify_texture(
      data.frame(gravel = 5, sand = 50, mud = 40),
      scheme = "gradistat",
      method = "rules",
      basis = "gravel_sand_mud"
    ),
    "sum to approximately 100"
  )
  expect_error(
    classify_texture(
      data.frame(sand = 50, silt = 50),
      scheme = "gradistat",
      method = "rules",
      basis = "sand_silt_clay_no_gravel"
    ),
    "requires columns"
  )
})

test_that("classify_texture polygon method does not silently use GRADISTAT rules", {
  samples <- data.frame(gravel = 0, sand = 95, mud = 5)

  expect_error(
    classify_texture(samples, scheme = "gradistat", method = "polygon", basis = "gravel_sand_mud"),
    "No built-in texture polygon dataset is bundled"
  )
})

test_that("GRADISTAT public path does not export helpers", {
  exports <- getNamespaceExports("grainsizeR")

  expect_true("classify_texture" %in% exports)
  expect_false(any(grepl("gradistat_texture_rules|classify_gradistat", exports)))
})
