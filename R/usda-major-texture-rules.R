#' Classify USDA major texture classes with validated internal rules
#'
#' Internal helper for the 12 USDA major texture ternary classes. Invalid
#' rows are retained and marked with `rule_status = "invalid"` so vectorized
#' callers can audit mixed input without losing row alignment.
#'
#' @noRd
.classify_usda_major_texture_rules <- function(sand, silt, clay, tol = 1e-8,
                                               validate_sum = TRUE,
                                               sum_tol = 1e-6) {
  input <- .validate_usda_major_texture_input(
    sand = sand,
    silt = silt,
    clay = clay,
    tol = tol,
    validate_sum = validate_sum,
    sum_tol = sum_tol
  )

  sand <- input$sand
  silt <- input$silt
  clay <- input$clay
  valid <- input$valid

  matches <- vector("list", length(sand))
  matches[!valid] <- list(character())
  if (any(valid)) {
    matches[valid] <- Map(
      .usda_major_texture_rule_matches,
      sand[valid],
      silt[valid],
      clay[valid],
      MoreArgs = list(tol = tol)
    )
  }

  n_matches <- lengths(matches)
  class_id <- rep(NA_character_, length(sand))
  one_match <- valid & n_matches == 1
  class_id[one_match] <- vapply(matches[one_match], `[`, character(1), 1)

  rule_conflict <- valid & n_matches > 1
  rule_gap <- valid & n_matches == 0
  rule_status <- rep("invalid", length(sand))
  rule_status[one_match] <- "classified"
  rule_status[rule_conflict] <- "conflict"
  rule_status[rule_gap] <- "gap"

  data.frame(
    sand = sand,
    silt = silt,
    clay = clay,
    class_id = class_id,
    class_name = unname(.usda_major_texture_class_names()[class_id]),
    all_rule_matches = vapply(matches, paste, character(1), collapse = ";"),
    rule_conflict = rule_conflict,
    rule_gap = rule_gap,
    rule_status = rule_status,
    stringsAsFactors = FALSE
  )
}

#' Match USDA major texture rules for one valid row
#'
#' @noRd
.usda_major_texture_rule_matches <- function(sand, silt, clay, tol = 1e-8) {
  gt <- function(x, y) x > y + tol
  ge <- function(x, y) x >= y - tol
  lt <- function(x, y) x < y - tol
  le <- function(x, y) x <= y + tol

  matches <- character()

  if (gt(sand, 85) && lt(silt + 1.5 * clay, 15)) {
    matches <- c(matches, "sand")
  }
  if (ge(sand, 70) && le(sand, 91) &&
      ge(silt + 1.5 * clay, 15) && lt(silt + 2 * clay, 30)) {
    matches <- c(matches, "loamy_sand")
  }
  if ((ge(clay, 7) && lt(clay, 20) && gt(sand, 52) &&
       ge(silt + 2 * clay, 30)) ||
      (lt(clay, 7) && lt(silt, 50) && gt(sand, 43) &&
       ge(silt + 2 * clay, 30))) {
    matches <- c(matches, "sandy_loam")
  }
  if (ge(clay, 7) && lt(clay, 27) && ge(silt, 28) &&
      lt(silt, 50) && le(sand, 52)) {
    matches <- c(matches, "loam")
  }
  if ((ge(silt, 50) && ge(clay, 12) && lt(clay, 27)) ||
      (ge(silt, 50) && lt(silt, 80) && lt(clay, 12))) {
    matches <- c(matches, "silt_loam")
  }
  if (ge(silt, 80) && lt(clay, 12)) {
    matches <- c(matches, "silt")
  }
  if (ge(clay, 20) && lt(clay, 35) && lt(silt, 28) && gt(sand, 45)) {
    matches <- c(matches, "sandy_clay_loam")
  }
  if (ge(clay, 27) && lt(clay, 40) && gt(sand, 20) &&
      (lt(sand, 45) || (le(sand, 45) && lt(clay, 35)))) {
    matches <- c(matches, "clay_loam")
  }
  if (ge(clay, 27) && lt(clay, 40) && le(sand, 20)) {
    matches <- c(matches, "silty_clay_loam")
  }
  if (ge(clay, 35) && ge(sand, 45)) {
    matches <- c(matches, "sandy_clay")
  }
  if (ge(clay, 40) && ge(silt, 40)) {
    matches <- c(matches, "silty_clay")
  }
  if (ge(clay, 40) && lt(sand, 45) && lt(silt, 40)) {
    matches <- c(matches, "clay")
  }

  unique(matches)
}

#' Validate USDA major texture rule inputs
#'
#' @noRd
.validate_usda_major_texture_input <- function(sand, silt, clay, tol = 1e-8,
                                               validate_sum = TRUE,
                                               sum_tol = 1e-6) {
  args <- list(sand = sand, silt = silt, clay = clay)
  lengths <- vapply(args, length, integer(1))
  target_length <- max(lengths)
  if (target_length == 0) {
    return(data.frame(
      sand = numeric(),
      silt = numeric(),
      clay = numeric(),
      valid = logical()
    ))
  }
  bad_length <- lengths != 1 & lengths != target_length
  if (any(bad_length)) {
    stop(
      "sand, silt, and clay must have length 1 or a common vector length.",
      call. = FALSE
    )
  }

  sand <- rep(as.numeric(sand), length.out = target_length)
  silt <- rep(as.numeric(silt), length.out = target_length)
  clay <- rep(as.numeric(clay), length.out = target_length)

  finite <- is.finite(sand) & is.finite(silt) & is.finite(clay)
  in_range <- finite &
    sand >= -tol & sand <= 100 + tol &
    silt >= -tol & silt <= 100 + tol &
    clay >= -tol & clay <= 100 + tol
  valid_sum <- rep(TRUE, target_length)
  if (isTRUE(validate_sum)) {
    valid_sum <- finite & abs(sand + silt + clay - 100) <= sum_tol
  }

  data.frame(
    sand = sand,
    silt = silt,
    clay = clay,
    valid = finite & in_range & valid_sum,
    stringsAsFactors = FALSE
  )
}

#' USDA major texture class names
#'
#' @noRd
.usda_major_texture_class_names <- function() {
  c(
    sand = "sand",
    loamy_sand = "loamy sand",
    sandy_loam = "sandy loam",
    loam = "loam",
    silt_loam = "silt loam",
    silt = "silt",
    sandy_clay_loam = "sandy clay loam",
    clay_loam = "clay loam",
    silty_clay_loam = "silty clay loam",
    sandy_clay = "sandy clay",
    silty_clay = "silty clay",
    clay = "clay"
  )
}
