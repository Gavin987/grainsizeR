test_that("texture_polygon_template returns required empty schema", {
  template <- texture_polygon_template()

  expect_s3_class(template, "tbl_df")
  expect_equal(nrow(template), 0)
  expect_named(template, c(
    "scheme",
    "class_id",
    "class_name",
    "vertex_id",
    "left",
    "right",
    "top",
    "left_component",
    "right_component",
    "top_component",
    "reference_id",
    "reference"
  ))
})

test_that("validate_texture_polygons accepts synthetic polygon", {
  polygons <- validate_texture_polygons(test_texture_polygons())

  expect_s3_class(polygons, "texture_polygons")
  expect_equal(nrow(polygons), 3)
})

test_that("validate_texture_polygons rejects invalid inputs", {
  polygons <- test_texture_polygons()

  expect_error(
    validate_texture_polygons(polygons[c("scheme", "class_id")]),
    "missing required columns"
  )

  expect_error(
    validate_texture_polygons(polygons[1:2, ]),
    "at least three vertices"
  )

  bad_sum <- polygons
  bad_sum$top[1] <- 1
  expect_error(
    validate_texture_polygons(bad_sum),
    "sum to approximately 100"
  )

  bad_mapping <- polygons
  bad_mapping$left_component[2] <- "gravel"
  expect_error(
    validate_texture_polygons(bad_mapping),
    "mapping must be consistent"
  )
})
