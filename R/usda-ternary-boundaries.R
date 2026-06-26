usda_ternary_grid <- function(step = 1) {
  rows <- list()
  row_id <- 1
  values <- seq(0, 100, by = step)
  for (sand in values) {
    for (silt in values) {
      clay <- 100 - sand - silt
      if (clay >= 0 && clay <= 100) {
        rows[[row_id]] <- data.frame(sand = sand, silt = silt, clay = clay)
        row_id <- row_id + 1
      }
    }
  }
  out <- do.call(rbind, rows)
  classes <- .classify_usda_major_texture_rules(out$sand, out$silt, out$clay)
  out$class_id <- classes$class_id
  out
}

usda_ternary_boundary_segments <- function(step = 0.5, eps = 0.15) {
  constraints <- list(
    list(type = "sand", value = 20),
    list(type = "sand", value = 43),
    list(type = "sand", value = 45),
    list(type = "sand", value = 52),
    list(type = "sand", value = 70),
    list(type = "sand", value = 85),
    list(type = "sand", value = 91),
    list(type = "silt", value = 28),
    list(type = "silt", value = 40),
    list(type = "silt", value = 50),
    list(type = "silt", value = 80),
    list(type = "clay", value = 7),
    list(type = "clay", value = 12),
    list(type = "clay", value = 20),
    list(type = "clay", value = 27),
    list(type = "clay", value = 35),
    list(type = "clay", value = 40),
    list(type = "silt_clay", value = 15, clay_weight = 1.5),
    list(type = "silt_clay", value = 30, clay_weight = 2)
  )
  rows <- list()
  row_id <- 1

  for (constraint in constraints) {
    points <- usda_constraint_points(constraint, step = step)
    if (nrow(points) < 2) {
      next
    }
    direction <- usda_constraint_normal(constraint)
    for (i in seq_len(nrow(points) - 1)) {
      mid <- colMeans(points[i:(i + 1), c("sand", "silt", "clay")])
      lower <- usda_project_to_triangle(mid - eps * direction)
      upper <- usda_project_to_triangle(mid + eps * direction)
      lower_class <- .classify_usda_major_texture_rules(lower[1], lower[2], lower[3])$class_id
      upper_class <- .classify_usda_major_texture_rules(upper[1], upper[2], upper[3])$class_id
      if (is.na(lower_class) || is.na(upper_class) || identical(lower_class, upper_class)) {
        next
      }
      a_xy <- ternary_to_xy(points$sand[i], points$silt[i], points$clay[i])
      b_xy <- ternary_to_xy(points$sand[i + 1], points$silt[i + 1], points$clay[i + 1])
      rows[[row_id]] <- data.frame(
        x = a_xy$x,
        y = a_xy$y,
        xend = b_xy$x,
        yend = b_xy$y,
        stringsAsFactors = FALSE
      )
      row_id <- row_id + 1
    }
  }

  if (length(rows) == 0) {
    return(tibble::tibble(x = numeric(), y = numeric(), xend = numeric(), yend = numeric()))
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

usda_constraint_points <- function(constraint, step) {
  values <- seq(0, 100, by = step)
  if (constraint$type == "sand") {
    silt <- values[values <= 100 - constraint$value]
    sand <- rep(constraint$value, length(silt))
    clay <- 100 - sand - silt
  } else if (constraint$type == "silt") {
    sand <- values[values <= 100 - constraint$value]
    silt <- rep(constraint$value, length(sand))
    clay <- 100 - sand - silt
  } else if (constraint$type == "clay") {
    sand <- values[values <= 100 - constraint$value]
    clay <- rep(constraint$value, length(sand))
    silt <- 100 - sand - clay
  } else {
    clay <- values
    silt <- constraint$value - constraint$clay_weight * clay
    keep <- silt >= 0
    clay <- clay[keep]
    silt <- silt[keep]
    sand <- 100 - silt - clay
  }
  keep <- sand >= 0 & silt >= 0 & clay >= 0 & sand <= 100 & silt <= 100 & clay <= 100
  data.frame(sand = sand[keep], silt = silt[keep], clay = clay[keep])
}

usda_constraint_normal <- function(constraint) {
  gradient <- switch(
    constraint$type,
    sand = c(1, 0, 0),
    silt = c(0, 1, 0),
    clay = c(0, 0, 1),
    silt_clay = c(0, 1, constraint$clay_weight)
  )
  direction <- gradient - mean(gradient)
  direction / sqrt(sum(direction^2))
}

usda_project_to_triangle <- function(x) {
  x <- pmax(x, 0)
  total <- sum(x)
  if (total == 0) {
    return(c(sand = 100 / 3, silt = 100 / 3, clay = 100 / 3))
  }
  x / total * 100
}

usda_ternary_label_data <- function() {
  points <- data.frame(
    class_id = c(
      "sand", "loamy_sand", "sandy_loam", "loam", "silt_loam", "silt",
      "sandy_clay_loam", "clay_loam", "silty_clay_loam",
      "sandy_clay", "silty_clay", "clay"
    ),
    sand = c(92, 78, 62, 42, 22, 8, 58, 34, 10, 52, 8, 22),
    silt = c(5, 15, 25, 38, 65, 88, 13, 34, 55, 7, 48, 22),
    clay = c(3, 7, 13, 20, 13, 4, 29, 32, 35, 41, 44, 56),
    stringsAsFactors = FALSE
  )
  xy <- ternary_to_xy(points$sand, points$silt, points$clay)
  names <- .usda_major_texture_class_names()
  data.frame(
    class_id = points$class_id,
    class_label = gsub(" ", "\n", unname(names[points$class_id]), fixed = TRUE),
    x = xy$x,
    y = xy$y,
    stringsAsFactors = FALSE
  )
}
