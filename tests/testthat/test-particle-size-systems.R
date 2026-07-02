test_that("particle_size_systems returns required particle-size metadata", {
  systems <- particle_size_systems()
  required_columns <- c(
    "system_id",
    "system_name",
    "country_or_region",
    "domain",
    "clay_upper_um",
    "silt_upper_um",
    "sand_upper_um",
    "gravel_lower_um",
    "clay_range",
    "silt_range",
    "sand_range",
    "gravel_range",
    "source_status",
    "source_reference",
    "notes"
  )

  expect_s3_class(systems, "tbl_df")
  expect_true(all(required_columns %in% names(systems)))
  expect_true(all(c(
    "wentworth_major",
    "gradistat",
    "usda",
    "isss",
    "uk_ssew",
    "hypres",
    "germany_63",
    "australia_20",
    "sweden_60"
  ) %in% systems$system_id))
  expect_false(any(c("aashto", "uscs") %in% systems$system_id))

  usda <- systems[systems$system_id == "usda", ]
  expect_equal(usda$clay_upper_um, 2)
  expect_equal(usda$silt_upper_um, 50)

  expect_equal(systems$silt_upper_um[systems$system_id == "isss"], 20)
  expect_equal(systems$silt_upper_um[systems$system_id == "uk_ssew"], 60)
  expect_equal(systems$silt_upper_um[systems$system_id == "germany_63"], 63)
})

test_that("texture_polygon_sources lists planned sources without coordinates", {
  sources <- texture_polygon_sources()
  required_columns <- c(
    "scheme",
    "scheme_name",
    "particle_size_system",
    "left_component",
    "right_component",
    "top_component",
    "polygon_status",
    "primary_source",
    "notes"
  )

  expect_s3_class(sources, "tbl_df")
  expect_true(all(required_columns %in% names(sources)))
  expect_true(all(c("usda", "hypres", "isss", "uk_ssew", "gradistat") %in% sources$scheme))
  expect_false(any(c("aashto", "uscs") %in% sources$scheme))
  expect_false(any(c("class_id", "class_name", "vertex_id", "left", "right", "top") %in% names(sources)))
  expect_true(all(sources$polygon_status == "planned"))
})
