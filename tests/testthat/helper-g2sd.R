g2sd_style_wide <- function(size_labels = c("2000", "1000", "500", "250", "125", "63", "40", "0")) {
  out <- data.frame(
    Q1 = c(5, 10, 15, 20, 20, 15, 10, 5),
    Q2 = c(4, 9, 16, 21, 19, 14, 11, 6),
    check.names = FALSE
  )
  rownames(out) <- size_labels
  out
}

g2sd_wide_to_long <- function(wide) {
  sizes <- rownames(wide)
  sample_cols <- names(wide)
  rows <- lapply(sample_cols, function(sample_col) {
    data.frame(
      sample_id = sample_col,
      size = sizes,
      retained_percent = wide[[sample_col]],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
