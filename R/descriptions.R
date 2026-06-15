#' Describe mean grain size from phi units
#'
#' @param phi A numeric vector of mean grain sizes in phi units.
#'
#' @return A character vector of grain-size class labels.
#' @export
describe_mean_size_phi <- function(phi) {
  out <- rep(NA_character_, length(phi))
  out[phi < -8] <- "boulder"
  out[phi >= -8 & phi < -6] <- "cobble"
  out[phi >= -6 & phi < -2] <- "pebble"
  out[phi >= -2 & phi < -1] <- "granule"
  out[phi >= -1 & phi < 0] <- "very coarse sand"
  out[phi >= 0 & phi < 1] <- "coarse sand"
  out[phi >= 1 & phi < 2] <- "medium sand"
  out[phi >= 2 & phi < 3] <- "fine sand"
  out[phi >= 3 & phi < 4] <- "very fine sand"
  out[phi >= 4 & phi < 5] <- "coarse silt"
  out[phi >= 5 & phi < 6] <- "medium silt"
  out[phi >= 6 & phi < 7] <- "fine silt"
  out[phi >= 7 & phi < 8] <- "very fine silt"
  out[phi >= 8] <- "clay"
  out
}

#' Describe Folk and Ward sorting
#'
#' @param sorting_phi A numeric vector of Folk and Ward sorting values in phi
#'   units.
#'
#' @return A character vector of sorting class labels.
#' @export
describe_sorting_fw <- function(sorting_phi) {
  out <- rep(NA_character_, length(sorting_phi))
  out[sorting_phi < 0.35] <- "very well sorted"
  out[sorting_phi >= 0.35 & sorting_phi < 0.50] <- "well sorted"
  out[sorting_phi >= 0.50 & sorting_phi < 0.71] <- "moderately well sorted"
  out[sorting_phi >= 0.71 & sorting_phi < 1.00] <- "moderately sorted"
  out[sorting_phi >= 1.00 & sorting_phi < 2.00] <- "poorly sorted"
  out[sorting_phi >= 2.00 & sorting_phi < 4.00] <- "very poorly sorted"
  out[sorting_phi >= 4.00] <- "extremely poorly sorted"
  out
}

#' Describe Folk and Ward skewness
#'
#' @param skewness A numeric vector of Folk and Ward skewness values.
#'
#' @return A character vector of skewness class labels.
#' @export
describe_skewness_fw <- function(skewness) {
  out <- rep(NA_character_, length(skewness))
  out[skewness >= 0.30] <- "strongly fine skewed"
  out[skewness >= 0.10 & skewness < 0.30] <- "fine skewed"
  out[skewness >= -0.10 & skewness < 0.10] <- "near symmetrical"
  out[skewness >= -0.30 & skewness < -0.10] <- "coarse skewed"
  out[skewness < -0.30] <- "strongly coarse skewed"
  out
}

#' Describe Folk and Ward kurtosis
#'
#' @param kurtosis A numeric vector of Folk and Ward kurtosis values.
#'
#' @return A character vector of kurtosis class labels.
#' @export
describe_kurtosis_fw <- function(kurtosis) {
  out <- rep(NA_character_, length(kurtosis))
  out[kurtosis < 0.67] <- "very platykurtic"
  out[kurtosis >= 0.67 & kurtosis < 0.90] <- "platykurtic"
  out[kurtosis >= 0.90 & kurtosis < 1.11] <- "mesokurtic"
  out[kurtosis >= 1.11 & kurtosis < 1.50] <- "leptokurtic"
  out[kurtosis >= 1.50 & kurtosis < 3.00] <- "very leptokurtic"
  out[kurtosis >= 3.00] <- "extremely leptokurtic"
  out
}
