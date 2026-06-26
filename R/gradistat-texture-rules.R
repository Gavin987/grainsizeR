.gradistat_class_names <- c(
  gravel = "gravel",
  sandy_gravel = "sandy gravel",
  gravelly_sand = "gravelly sand",
  slightly_gravelly_sand = "slightly gravelly sand",
  sand = "sand",
  muddy_sandy_gravel = "muddy sandy gravel",
  gravelly_muddy_sand = "gravelly muddy sand",
  slightly_gravelly_muddy_sand = "slightly gravelly muddy sand",
  muddy_sand = "muddy sand",
  muddy_gravel = "muddy gravel",
  gravelly_mud = "gravelly mud",
  slightly_gravelly_sandy_mud = "slightly gravelly sandy mud",
  sandy_mud = "sandy mud",
  slightly_gravelly_mud = "slightly gravelly mud",
  mud = "mud",
  silty_sand = "silty sand",
  clayey_sand = "clayey sand",
  sandy_silt = "sandy silt",
  sandy_clay = "sandy clay",
  silt = "silt",
  clay = "clay"
)

.gradistat_safe_ratio <- function(numerator, denominator) {
  out <- numerator / denominator
  out[denominator == 0 & numerator > 0] <- Inf
  out[numerator == 0 & denominator > 0] <- 0
  out[numerator == 0 & denominator == 0] <- NA_real_
  out
}

.validate_gradistat_texture_input <- function(x, basis, sum_tol = 1e-6) {
  basis <- match.arg(basis, c("gravel_sand_mud", "sand_silt_clay_no_gravel"))
  required <- if (basis == "gravel_sand_mud") {
    c("gravel", "sand", "mud")
  } else {
    c("sand", "silt", "clay")
  }

  if (!is.data.frame(x)) {
    stop("GRADISTAT rule classification requires a data frame input.", call. = FALSE)
  }
  missing_cols <- setdiff(required, names(x))
  if (length(missing_cols) > 0) {
    stop(
      "GRADISTAT `", basis, "` classification requires columns: ",
      paste(required, collapse = ", "),
      call. = FALSE
    )
  }

  out <- tibble::as_tibble(x)
  for (column in required) {
    if (!is.numeric(out[[column]])) {
      stop("GRADISTAT texture percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
    }
  }

  values <- out[required]
  invalid <- Reduce(`|`, lapply(values, function(value) {
    !is.finite(value) | value < 0 | value > 100
  }))
  if (any(invalid)) {
    stop("GRADISTAT texture percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
  }

  sums <- rowSums(as.data.frame(values))
  if (any(abs(sums - 100) > sum_tol)) {
    stop("GRADISTAT texture percentages must sum to approximately 100 for the selected basis.", call. = FALSE)
  }

  out
}

.classify_gradistat_gravel_sand_mud <- function(gravel, sand, mud) {
  ratio <- .gradistat_safe_ratio(sand, mud)
  class_id <- rep(NA_character_, length(gravel))

  class_id[gravel >= 80] <- "gravel"

  mid_gravel <- is.na(class_id) & gravel >= 30
  class_id[mid_gravel & ratio >= 9] <- "sandy_gravel"
  class_id[mid_gravel & ratio < 9 & ratio >= 1 / 9] <- "muddy_sandy_gravel"
  class_id[mid_gravel & ratio < 1 / 9] <- "muddy_gravel"

  gravelly <- is.na(class_id) & gravel >= 5
  class_id[gravelly & ratio >= 9] <- "gravelly_sand"
  class_id[gravelly & ratio < 9 & ratio >= 1] <- "gravelly_muddy_sand"
  class_id[gravelly & ratio < 1] <- "gravelly_mud"

  slightly <- is.na(class_id) & gravel > 0
  class_id[slightly & ratio >= 9] <- "slightly_gravelly_sand"
  class_id[slightly & ratio < 9 & ratio >= 1] <- "slightly_gravelly_muddy_sand"
  class_id[slightly & ratio < 1 & ratio >= 1 / 9] <- "slightly_gravelly_sandy_mud"
  class_id[slightly & ratio < 1 / 9] <- "slightly_gravelly_mud"

  no_gravel <- is.na(class_id) & gravel == 0
  class_id[no_gravel & ratio >= 9] <- "sand"
  class_id[no_gravel & ratio < 9 & ratio >= 1] <- "muddy_sand"
  class_id[no_gravel & ratio < 1 & ratio >= 1 / 9] <- "sandy_mud"
  class_id[no_gravel & ratio < 1 / 9] <- "mud"

  data.frame(
    texture_class_id = class_id,
    texture_class = unname(.gradistat_class_names[class_id]),
    ratio = ratio,
    stringsAsFactors = FALSE
  )
}

.classify_gradistat_sand_silt_clay_no_gravel <- function(sand, silt, clay) {
  ratio <- .gradistat_safe_ratio(silt, clay)
  class_id <- rep(NA_character_, length(sand))

  high_sand <- sand >= 90
  class_id[high_sand] <- "sand"

  sandy <- is.na(class_id) & sand >= 50
  class_id[sandy & ratio >= 2] <- "silty_sand"
  class_id[sandy & ratio < 2 & ratio > 0.5] <- "muddy_sand"
  class_id[sandy & ratio <= 0.5] <- "clayey_sand"

  mixed <- is.na(class_id) & sand >= 10
  class_id[mixed & ratio >= 2] <- "sandy_silt"
  class_id[mixed & ratio < 2 & ratio > 0.5] <- "sandy_mud"
  class_id[mixed & ratio <= 0.5] <- "sandy_clay"

  low_sand <- is.na(class_id)
  class_id[low_sand & ratio >= 2] <- "silt"
  class_id[low_sand & ratio < 2 & ratio > 0.5] <- "mud"
  class_id[low_sand & ratio <= 0.5] <- "clay"

  data.frame(
    texture_class_id = class_id,
    texture_class = unname(.gradistat_class_names[class_id]),
    ratio = ratio,
    stringsAsFactors = FALSE
  )
}

.classify_gradistat_texture_rules <- function(x,
                                              basis = c("gravel_sand_mud", "sand_silt_clay_no_gravel"),
                                              sum_tol = 1e-6) {
  basis <- match.arg(basis)
  input <- .validate_gradistat_texture_input(x, basis = basis, sum_tol = sum_tol)
  classified <- if (basis == "gravel_sand_mud") {
    .classify_gradistat_gravel_sand_mud(input$gravel, input$sand, input$mud)
  } else {
    .classify_gradistat_sand_silt_clay_no_gravel(input$sand, input$silt, input$clay)
  }

  out <- input
  out$texture_class_id <- classified$texture_class_id
  out$texture_class <- classified$texture_class
  out$ternary_basis <- basis
  out$classification_method <- "gradistat_texture_rules"
  out$classification_status <- ifelse(is.na(classified$texture_class_id), "needs_review", "classified")
  out$notes <- ifelse(
    out$classification_status == "classified",
    NA_character_,
    "No GRADISTAT decision-table class matched this row."
  )
  if (basis == "gravel_sand_mud") {
    out$sand_mud_ratio <- classified$ratio
  } else {
    out$silt_clay_ratio <- classified$ratio
  }

  tibble::as_tibble(out)
}
