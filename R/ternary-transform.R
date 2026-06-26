#' Convert ternary coordinates to Cartesian coordinates
#'
#' `ternary_to_xy()` converts left, right, and top ternary percentages to
#' Cartesian coordinates for an equilateral triangle. The transformation uses
#' public-domain triangle geometry and does not depend on external texture
#' classification data.
#'
#' @param left Numeric vector for the left-axis component.
#' @param right Numeric vector for the right-axis component.
#' @param top Numeric vector for the top-axis component.
#' @param normalize Should rows be normalized so `left + right + top = 100`?
#'
#' @return A tibble with Cartesian coordinates and normalized ternary values.
#' @export
ternary_to_xy <- function(left, right, top, normalize = TRUE) {
  if (!is.numeric(left) || !is.numeric(right) || !is.numeric(top)) {
    stop("`left`, `right`, and `top` must be numeric vectors.", call. = FALSE)
  }

  n <- max(length(left), length(right), length(top))
  left <- rep(left, length.out = n)
  right <- rep(right, length.out = n)
  top <- rep(top, length.out = n)

  if (anyNA(left) || anyNA(right) || anyNA(top)) {
    stop("Ternary component values must not be missing.", call. = FALSE)
  }

  if (normalize) {
    total <- left + right + top
    if (any(total <= 0)) {
      stop("Ternary component totals must be positive when `normalize = TRUE`.", call. = FALSE)
    }
    left <- left / total * 100
    right <- right / total * 100
    top <- top / total * 100
  }

  right_prop <- right / 100
  top_prop <- top / 100

  tibble::tibble(
    x = right_prop + 0.5 * top_prop,
    y = sqrt(3) / 2 * top_prop,
    left = left,
    right = right,
    top = top
  )
}
