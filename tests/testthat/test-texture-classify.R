test_that("classify_texture classifies resolvable samples", {
  gsd <- fine_texture_gsd()
  result <- classify_texture(gsd, test_texture_polygons(), scheme = "test_triangle")

  expect_equal(result$class_name, c("All triangle", "All triangle"))
  expect_true(all(result$resolved))
  expect_false(any(result$ambiguous))
  expect_true(all(c("left", "right", "top", "x", "y") %in% names(result)))
})

test_that("classify_texture resolves closed fraction partitions for coarse samples", {
  gsd <- as_gsd_tbl(
    ragged_input_phase2[ragged_input_phase2$sample_id == "WN1", ],
    sample_id,
    size_mm,
    retained_proportion
  )

  result <- classify_texture(gsd, test_texture_polygons(), scheme = "test_triangle")

  expect_true(result$resolved)
  expect_equal(result$class_id, "all")
  expect_equal(result$class_name, "All triangle")
})

test_that("classify_texture marks ambiguous polygon matches", {
  polygons <- rbind(
    test_texture_polygons(),
    transform(test_texture_polygons(), class_id = "all2", class_name = "All triangle 2")
  )

  result <- classify_texture(fine_texture_gsd(), polygons, scheme = "test_triangle")

  expect_true(all(result$ambiguous))
  expect_equal(result$class_id, c("all", "all"))
})
