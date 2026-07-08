with_known_extrapolation_warnings <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (is_known_extrapolation_warning(w)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

with_one_known_extrapolation_warning <- function(expr) {
  seen <- FALSE
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (!is_known_extrapolation_warning(w)) {
        return()
      }
      if (seen) {
        invokeRestart("muffleWarning")
      }
      seen <<- TRUE
    }
  )
}

is_known_extrapolation_warning <- function(w) {
  grepl(
    "^Requested (thresholds|percentiles) for sample `[^`]+` fall outside the finite boundary (size|curve) range; linearly extrapolating\\.$",
    conditionMessage(w)
  )
}
