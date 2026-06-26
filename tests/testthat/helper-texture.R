test_texture_polygons <- function() {
  data.frame(
    scheme = "test_triangle",
    class_id = "all",
    class_name = "All triangle",
    vertex_id = 1:3,
    left = c(100, 0, 0),
    right = c(0, 100, 0),
    top = c(0, 0, 100),
    left_component = "sand",
    right_component = "silt",
    top_component = "clay",
    reference_id = NA_character_,
    reference = NA_character_
  )
}

fine_texture_gsd <- function() {
  x <- data.frame(
    sample_id = c("A", "A", "A", "A", "B", "B", "B", "B"),
    size_mm = rep(c(2, 0.05, 0.002, 0.001), 2),
    retained_proportion = c(
      0.10, 0.40, 0.30, 0.20,
      0.05, 0.20, 0.35, 0.40
    )
  )
  as_gsd_tbl(x, sample_id, size_mm, retained_proportion)
}
