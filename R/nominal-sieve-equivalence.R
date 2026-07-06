#' List known nominal sieve-mesh equivalence groups
#'
#' `nominal_sieve_equivalence_groups_mm()` returns known groups of
#' particle-size boundary values (in millimetres) that real-world sieve
#' manufacturing and significant-figure conventions treat as the same
#' physical sieve cut, even though they are numerically distinct as stored.
#' This is an explicit, auditable table, not a numeric tolerance formula -
#' only listed groups are ever treated as equivalent, and every group must
#' be backed by a citation. Do not add a group without one.
#'
#' Group 1: `0.0625` mm (1/16 mm, phi = 4, the exact Udden-Wentworth
#' phi-scale theoretical boundary used by `wentworth_major` and
#' `wentworth_detailed`) and `0.063` mm (the real manufactured sieve
#' aperture under ISO 3310-1 and ASTM E11's R20/3 preferred-number series,
#' also matching DIN 4188; this is the value `gravel_sand_mud`,
#' `gradistat`, and `germany_63` use, following GRADISTAT / Blott and Pye
#' (2001)). No sieve manufacturer cuts a 0.0625 mm mesh; a sieve certified
#' near this size under either standard is labelled 0.063 mm (equivalently,
#' US/ASTM No. 230 mesh, nominal 63 μm).
#'
#' Other built-in scheme boundaries reviewed and found NOT to warrant an
#' equivalence group (see `dev-notes/AUDIT_LOG.md`'s scheme inventory for
#' the full review): `usda`/`hypres`'s 50 μm, `isss`/`australia_20`'s
#' 20 μm, and `gravel_sand_mud`/`gradistat`/`germany_63`'s 63 μm are
#' themselves real, standard ISO 3310-1 R20 preferred-number apertures with
#' no theoretical-vs-manufactured gap. `uk_ssew` and `sweden_60` use a 60
#' μm boundary that is not itself a real ISO/ASTM preferred-number
#' aperture; whether it warrants its own equivalence group is a separate,
#' unverified question with no established connection to the
#' 0.0625/0.063 mm case above, and it is deliberately NOT included below
#' pending its own primary-source citation.
#'
#' @return A list of numeric vectors; each vector is one equivalence group.
#' @noRd
nominal_sieve_equivalence_groups_mm <- function() {
  list(
    c(0.0625, 0.063)
  )
}

#' Test whether two sizes are the same nominal sieve mesh
#'
#' `TRUE` if `a_mm` and `b_mm` are the same value (within `tol`), or are
#' both members of a shared group returned by
#' `nominal_sieve_equivalence_groups_mm()`. Matching is against each
#' group's listed constants only, not a general numeric tolerance around
#' arbitrary values - unrelated boundaries (e.g. USDA's 0.05 mm) are never
#' equivalenced just for being numerically close to something else.
#'
#' @param a_mm,b_mm Single numeric values, in millimetres.
#' @param tol Numeric tolerance for floating-point equality.
#'
#' @return A single logical value.
#' @noRd
is_nominally_equivalent_mm <- function(a_mm, b_mm, tol = 1e-9) {
  if (isTRUE(all.equal(a_mm, b_mm, tolerance = tol))) {
    return(TRUE)
  }
  for (group in nominal_sieve_equivalence_groups_mm()) {
    a_in_group <- any(vapply(group, function(g) isTRUE(all.equal(a_mm, g, tolerance = tol)), logical(1)))
    b_in_group <- any(vapply(group, function(g) isTRUE(all.equal(b_mm, g, tolerance = tol)), logical(1)))
    if (a_in_group && b_in_group) {
      return(TRUE)
    }
  }
  FALSE
}

#' Find a nominally-equivalent boundary
#'
#' Returns the first value in `boundary_values_mm` that is nominally
#' equivalent to `threshold_mm` (see `is_nominally_equivalent_mm()`), or
#' `NA_real_` if none match. If more than one boundary value would match,
#' the first one encountered (in `boundary_values_mm`'s given order) is
#' used - deterministic, but only relevant in the unlikely case that a
#' sample's own finite boundaries include more than one member of the same
#' equivalence group.
#'
#' @param threshold_mm A single numeric threshold, in millimetres.
#' @param boundary_values_mm A numeric vector of boundary values, in
#'   millimetres, to search for a nominal-equivalence match.
#'
#' @return A single numeric value (the matched boundary) or `NA_real_`.
#' @noRd
nominally_equivalent_boundary_mm <- function(threshold_mm, boundary_values_mm) {
  for (b in boundary_values_mm) {
    if (is_nominally_equivalent_mm(threshold_mm, b)) {
      return(b)
    }
  }
  NA_real_
}

#' Find a nominally-equivalent boundary (micrometre-scale convenience wrapper)
#'
#' Micrometre-scale wrapper around `nominally_equivalent_boundary_mm()`, for
#' callers (like `gs_percent_finer()`'s internals) that work in micrometres.
#'
#' @param threshold_um A single numeric threshold, in micrometres.
#' @param boundary_values_um A numeric vector of boundary values, in
#'   micrometres.
#'
#' @return A single numeric value (the matched boundary, in micrometres) or
#'   `NA_real_`.
#' @noRd
nominally_equivalent_boundary_um <- function(threshold_um, boundary_values_um) {
  match_mm <- nominally_equivalent_boundary_mm(um_to_mm(threshold_um), um_to_mm(boundary_values_um))
  if (is.na(match_mm)) {
    return(NA_real_)
  }
  mm_to_um(match_mm)
}
