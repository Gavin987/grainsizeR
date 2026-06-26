alias_test_gsd <- function() {
  as_gsd_tbl(
    ragged_input_phase2,
    sample_id,
    size_mm,
    retained_proportion
  )
}

alias_test_fine_gsd <- function() {
  as_gsd_tbl(
    data.frame(
      sample_id = "A",
      size_mm = c(2, 1, 0.5, 0.25, 0.125, 0.063, 0.031, 0.016, 0.008, 0.004, 0.002, 0.001),
      retained = c(2, 3, 5, 10, 15, 18, 12, 10, 8, 7, 6, 4)
    ),
    sample_id,
    size_mm,
    retained,
    value_type = "percent"
  )
}

expect_same_plot_contract <- function(alias_plot, full_plot) {
  expect_s3_class(alias_plot, "ggplot")
  expect_s3_class(full_plot, "ggplot")
  expect_equal(length(alias_plot$layers), length(full_plot$layers))
  expect_equal(names(alias_plot$labels), names(full_plot$labels))
}

test_that("new convenience aliases are exported", {
  exports <- getNamespaceExports("grainsizeR")
  expect_true(all(c(
    "gs_fw57", "gs_frac", "gs_frac_schemes", "gs_frac_wide",
    "gs_diag", "gs_desc", "gs_qc", "plot_texture_ternary"
  ) %in% exports))
})

test_that("grain-size convenience aliases match full functions", {
  gsd <- alias_test_gsd()
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  expect_equal(gs_fw57(wn2), gs_folk_ward(wn2))
  expect_equal(gs_frac(gsd, scheme = "wentworth_major"), gs_fractions(gsd, scheme = "wentworth_major"))
  expect_equal(gs_frac_schemes(), gs_fraction_schemes())
  expect_equal(gs_frac_wide(gsd, scheme = "wentworth_major"), gs_fractions_wide(gsd, scheme = "wentworth_major"))
  expect_equal(gs_diag(gsd, output = "summary"), gs_diagnostics(gsd, output = "summary"))

  descriptor_input <- data.frame(
    sample_id = "A",
    mean_fw_phi = 2.5,
    sorting_fw_phi = 0.5,
    skewness_fw = 0,
    kurtosis_fw = 1
  )
  expect_equal(gs_desc(descriptor_input), gs_describe_parameters(descriptor_input))
  expect_equal(gs_qc(gsd), gs_quality_flags(gsd))
})

test_that("plot_texture_ternary matches texture ternary plotting behavior", {
  gsm <- data.frame(
    sample_id = c("A", "B", "C"),
    gravel = c(0, 10, 40),
    sand = c(95, 80, 40),
    mud = c(5, 10, 20)
  )
  ssc <- data.frame(
    sample_id = c("A", "B", "C"),
    sand = c(95, 60, 20),
    silt = c(3, 30, 60),
    clay = c(2, 10, 20)
  )
  usda_gs <- alias_test_fine_gsd()

  expect_same_plot_contract(
    plot_texture_ternary(gsm, scheme = "gradistat", basis = "gravel_sand_mud", point_id = "sample_id"),
    plot_texture_triangle(gsm, scheme = "gradistat", basis = "gravel_sand_mud", point_id = "sample_id")
  )

  expect_same_plot_contract(
    suppressWarnings(plot_texture_ternary(usda_gs, scheme = "usda_tt")),
    suppressWarnings(plot_texture_triangle(usda_gs, scheme = "usda_tt"))
  )

  expect_same_plot_contract(
    plot_texture_ternary(ssc, scheme = "gradistat", basis = "sand_silt_clay_no_gravel", point_id = "sample_id"),
    plot_texture_triangle(ssc, scheme = "gradistat", basis = "sand_silt_clay_no_gravel", point_id = "sample_id")
  )
})

test_that("existing compatibility aliases still work", {
  gsd <- alias_test_gsd()
  wn2 <- gsd[gsd$sample_id == "WN2", ]

  expect_equal(gs_percentile(gsd, probs = c(10, 50)), gs_d_values(gsd, probs = c(10, 50)))
  expect_equal(gs_folkward(wn2), gs_folk_ward(wn2))
  expect_s3_class(suppressWarnings(plot_trigon(alias_test_fine_gsd(), scheme = "usda_tt")), "ggplot")
})
