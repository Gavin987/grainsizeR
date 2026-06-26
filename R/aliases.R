#' Convenience alias for Folk and Ward graphical statistics
#'
#' `gs_fw57()` is a short convenience alias for [gs_folk_ward()]. It does not
#' change calculation behavior.
#'
#' @param ... Arguments forwarded to [gs_folk_ward()].
#' @return See [gs_folk_ward()].
#' @export
gs_fw57 <- function(...) {
  gs_folk_ward(...)
}

#' Convenience alias for grain-size fractions
#'
#' `gs_frac()` is a short convenience alias for [gs_fractions()]. It does not
#' change calculation behavior.
#'
#' @param ... Arguments forwarded to [gs_fractions()].
#' @return See [gs_fractions()].
#' @export
gs_frac <- function(...) {
  gs_fractions(...)
}

#' Convenience alias for fraction schemes
#'
#' `gs_frac_schemes()` is a short convenience alias for
#' [gs_fraction_schemes()]. It does not change behavior.
#'
#' @return See [gs_fraction_schemes()].
#' @export
gs_frac_schemes <- function() {
  gs_fraction_schemes()
}

#' Convenience alias for wide grain-size fractions
#'
#' `gs_frac_wide()` is a short convenience alias for [gs_fractions_wide()]. It
#' does not change calculation behavior.
#'
#' @param ... Arguments forwarded to [gs_fractions_wide()].
#' @return See [gs_fractions_wide()].
#' @export
gs_frac_wide <- function(...) {
  gs_fractions_wide(...)
}

#' Convenience alias for grain-size diagnostics
#'
#' `gs_diag()` is a short convenience alias for [gs_diagnostics()]. It does not
#' change diagnostic behavior.
#'
#' @param ... Arguments forwarded to [gs_diagnostics()].
#' @return See [gs_diagnostics()].
#' @export
gs_diag <- function(...) {
  gs_diagnostics(...)
}

#' Convenience alias for descriptive parameter terms
#'
#' `gs_desc()` is a short convenience alias for [gs_describe_parameters()]. It
#' does not change calculation behavior.
#'
#' @param ... Arguments forwarded to [gs_describe_parameters()].
#' @return See [gs_describe_parameters()].
#' @export
gs_desc <- function(...) {
  gs_describe_parameters(...)
}

#' Convenience alias for grain-size quality flags
#'
#' `gs_qc()` is a short convenience alias for [gs_quality_flags()]. It does not
#' change diagnostic behavior.
#'
#' @param ... Arguments forwarded to [gs_quality_flags()].
#' @return See [gs_quality_flags()].
#' @export
gs_qc <- function(...) {
  gs_quality_flags(...)
}

#' Preferred alias for texture ternary plots
#'
#' `plot_texture_ternary()` is the preferred terminology-correct name for
#' [plot_texture_triangle()]. Both functions create texture ternary plots and
#' return ggplot objects. `plot_texture_triangle()` remains available for API
#' stability.
#'
#' @param ... Arguments forwarded to [plot_texture_triangle()].
#' @return See [plot_texture_triangle()].
#' @export
plot_texture_ternary <- function(...) {
  plot_texture_triangle(...)
}
