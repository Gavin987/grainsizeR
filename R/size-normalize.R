.gsd_size_mm <- function(x) {
  if (is.data.frame(x)) {
    if ("raw_size_um" %in% names(x)) {
      return(as.numeric(x$raw_size_um) / 1000)
    }
    if ("size_mm" %in% names(x)) {
      return(as.numeric(x$size_mm))
    }
    if ("size_um" %in% names(x)) {
      return(as.numeric(x$size_um) / 1000)
    }
    stop("No recognized grain-size column was found.", call. = FALSE)
  }

  size <- suppressWarnings(as.numeric(x))
  positive <- size[is.finite(size) & size > 0]
  if (length(positive) > 0 && any(positive >= 1000)) {
    size / 1000
  } else {
    size
  }
}

.gsd_tbl_with_normalized_mm_sizes <- function(x) {
  out <- x
  out$raw_size_um <- .gsd_size_mm(out) * 1000
  out
}
