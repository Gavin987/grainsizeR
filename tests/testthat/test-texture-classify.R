test_that("classify_texture classifies resolvable samples", {
  gsd <- fine_texture_gsd()
  result <- classify_texture(gsd, test_texture_polygons(), scheme = "test_triangle")

  expect_equal(result$texture_class, c("All triangle", "All triangle"))
  expect_true(all(result$resolved))
  expect_false(any(result$ambiguous))
  expect_true(all(c("left", "right", "top", "x", "y") %in% names(result)))
})

test_that("classify_texture resolves closed fraction partitions for coarse samples", {
  # A genuinely coarse (sieve-only) sample with zero pan mass: this
  # scheme's underlying USDA-equivalent silt/clay boundaries (see
  # built_in_fraction_scheme()) fall below the finest measured boundary,
  # but resolve cleanly to 0 percent since there is truly nothing finer
  # (no assumption required - see dev-notes/AUDIT_LOG.md's root-cause
  # entry). WN1 (ragged_input_phase2) has real, nonzero pan mass instead,
  # which requires extrapolation and can classify well outside the
  # triangle for such a large gap - not a meaningful fixture for this
  # "coarse sample resolves cleanly" case.
  gsd <- as_gsd_tbl(
    data.frame(
      sample_id = "coarse",
      size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.001),
      retained = c(5, 10, 20, 30, 25, 10, 0)
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )

  result <- classify_texture(gsd, test_texture_polygons(), scheme = "test_triangle")

  expect_true(result$resolved)
  expect_equal(result$texture_class_id, "all")
  expect_equal(result$texture_class, "All triangle")
})

test_that("classify_texture marks ambiguous polygon matches", {
  polygons <- rbind(
    test_texture_polygons(),
    transform(test_texture_polygons(), class_id = "all2", class_name = "All triangle 2")
  )

  result <- classify_texture(fine_texture_gsd(), polygons, scheme = "test_triangle")

  expect_true(all(result$ambiguous))
  expect_equal(result$texture_class_id, c("all", "all"))
})
