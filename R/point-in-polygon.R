point_on_segment <- function(px, py, x1, y1, x2, y2, tolerance) {
  cross <- (px - x1) * (y2 - y1) - (py - y1) * (x2 - x1)
  if (abs(cross) > tolerance) {
    return(FALSE)
  }

  px >= min(x1, x2) - tolerance &&
    px <= max(x1, x2) + tolerance &&
    py >= min(y1, y2) - tolerance &&
    py <= max(y1, y2) + tolerance
}

point_in_polygon <- function(x, y, poly_x, poly_y, tolerance = 1e-9) {
  n_points <- max(length(x), length(y))
  x <- rep(x, length.out = n_points)
  y <- rep(y, length.out = n_points)

  if (length(poly_x) != length(poly_y) || length(poly_x) < 3) {
    stop("A polygon must contain at least three x/y vertices.", call. = FALSE)
  }

  out <- logical(n_points)
  n_vertices <- length(poly_x)

  for (i in seq_len(n_points)) {
    inside <- FALSE
    boundary <- FALSE
    j <- n_vertices

    for (k in seq_len(n_vertices)) {
      if (point_on_segment(x[i], y[i], poly_x[j], poly_y[j], poly_x[k], poly_y[k], tolerance)) {
        boundary <- TRUE
        break
      }

      intersects <- ((poly_y[k] > y[i]) != (poly_y[j] > y[i])) &&
        (x[i] < (poly_x[j] - poly_x[k]) * (y[i] - poly_y[k]) / (poly_y[j] - poly_y[k]) + poly_x[k])
      if (intersects) {
        inside <- !inside
      }
      j <- k
    }

    out[i] <- boundary || inside
  }

  out
}
