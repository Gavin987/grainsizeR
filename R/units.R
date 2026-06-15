#' Convert millimeters to micrometers
#'
#' @param x A numeric vector of sizes in millimeters.
#'
#' @return A numeric vector of sizes in micrometers.
#' @export
mm_to_um <- function(x) {
  x * 1000
}

#' Convert micrometers to millimeters
#'
#' @param x A numeric vector of sizes in micrometers.
#'
#' @return A numeric vector of sizes in millimeters.
#' @export
um_to_mm <- function(x) {
  x / 1000
}

#' Convert millimeters to phi units
#'
#' Phi is calculated as `-log2(size_mm)`.
#'
#' @param x A numeric vector of sizes in millimeters.
#'
#' @return A numeric vector of phi sizes.
#' @export
mm_to_phi <- function(x) {
  -log2(x)
}

#' Convert micrometers to phi units
#'
#' @param x A numeric vector of sizes in micrometers.
#'
#' @return A numeric vector of phi sizes.
#' @export
um_to_phi <- function(x) {
  mm_to_phi(um_to_mm(x))
}

#' Convert phi units to millimeters
#'
#' @param x A numeric vector of phi sizes.
#'
#' @return A numeric vector of sizes in millimeters.
#' @export
phi_to_mm <- function(x) {
  2^(-x)
}

#' Convert phi units to micrometers
#'
#' @param x A numeric vector of phi sizes.
#'
#' @return A numeric vector of sizes in micrometers.
#' @export
phi_to_um <- function(x) {
  mm_to_um(phi_to_mm(x))
}
