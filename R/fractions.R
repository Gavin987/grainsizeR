scheme_components <- function(scheme) {
  scheme <- .validate_fraction_scheme(scheme)
  schemes <- gs_fraction_schemes()
  out <- schemes[schemes$scheme == scheme, ]
  out
}

required_fraction_thresholds <- function(components) {
  sort(unique(c(
    components$lower_mm[is.finite(components$lower_mm) & components$lower_mm > 0],
    components$upper_mm[is.finite(components$upper_mm) & components$upper_mm > 0]
  )))
}

percent_finer_lookup <- function(x, thresholds_mm, interpolation_scale, extrapolate, unresolved) {
  sample_ids <- unique(as.character(x$sample_id))
  normalized_x <- .gsd_tbl_with_normalized_mm_sizes(x)

  if (length(thresholds_mm) == 0) {
    return(tibble::tibble(
      sample_id = character(),
      threshold_mm = numeric(),
      threshold_um = numeric(),
      percent_finer = numeric(),
      resolved = logical()
    ))
  }

  split_x <- split(normalized_x, normalized_x$sample_id, drop = TRUE)

  rows <- list()
  row_id <- 1
  unresolved_seen <- FALSE
  for (sample_id in sample_ids) {
    sample_x <- split_x[[sample_id]]
    curve <- gs_cumulative(sample_x)
    finite_mm <- curve$boundary_mm
    min_mm <- min(finite_mm)
    max_mm <- max(finite_mm)

    # Nominal sieve-mesh equivalence (see R/nominal-sieve-equivalence.R): a
    # threshold below/above the sample's finite range may still be directly
    # resolvable if it is a recognized equivalence match for one of the
    # sample's own finite boundaries (e.g. gravel_sand_mud's 63 μm vs
    # wentworth_major's 62.5 μm on the same real sieve). Such thresholds are
    # routed into the batched gs_percent_finer() call below like any other
    # in-range threshold - gs_percent_finer()'s own equivalence-aware logic
    # then resolves them from the matched boundary's real value, not as an
    # extrapolation.
    equivalent_boundary <- vapply(
      thresholds_mm,
      function(t) nominally_equivalent_boundary_mm(t, finite_mm),
      numeric(1)
    )
    has_equivalent <- !is.na(equivalent_boundary)

    in_range <- (thresholds_mm >= min_mm & thresholds_mm <= max_mm) | has_equivalent
    resolved_lookup <- NULL
    if (any(in_range)) {
      # One batched call per sample for every in-range threshold, instead of
      # one call per threshold: `gs_percent_finer()` already vectorizes over
      # `sizes` and only needs to rebuild the cumulative curve once.
      resolved_lookup <- tryCatch(
        gs_percent_finer(
          sample_x,
          sizes = thresholds_mm[in_range],
          size_unit = "mm",
          interpolation_scale = interpolation_scale,
          extrapolate = extrapolate
        ),
        error = function(err) NULL
      )
    }

    for (i in seq_along(thresholds_mm)) {
      threshold <- thresholds_mm[i]
      threshold_has_equivalent <- has_equivalent[i]

      if (threshold < min_mm && !threshold_has_equivalent) {
        # Genuinely below the finest measured boundary, with no recognized
        # nominal-equivalence match. Whether this is a confident 0% depends
        # on whether the excluded open-lower (pan) row actually carries
        # retained mass - see dev-notes/AUDIT_LOG.md, "Root-cause:
        # gs_fractions() below-finest-boundary behavior", for the full
        # investigation this fix implements. If the pan is empty, 0% finer
        # is exactly correct (no assumption involved); if it is not, the
        # true value is not derivable from the data, and this now follows
        # the same extrapolate policy gs_percent_finer() uses for the
        # identical situation, instead of silently hard-coding zero.
        pan_retained <- sum(sample_x$retained_percent[sample_x$is_open_lower], na.rm = TRUE)
        if (!is.finite(pan_retained) || pan_retained <= 0) {
          rows[[row_id]] <- tibble::tibble(
            sample_id = sample_id,
            threshold_mm = threshold,
            threshold_um = mm_to_um(threshold),
            percent_finer = 0,
            resolved = TRUE
          )
        } else if (extrapolate == "error") {
          stop(
            "Requested fraction threshold falls inside an open-ended (pan) ",
            "class with nonzero retained mass for sample `", sample_id,
            "`. Use `extrapolate = \"warn_linear\"` to extrapolate.",
            call. = FALSE
          )
        } else {
          # extrapolate == "warn_linear": defer to gs_percent_finer()'s own
          # linear extrapolation (with its own warning) instead of
          # hard-coding a value.
          extrapolated_lookup <- tryCatch(
            gs_percent_finer(
              sample_x,
              sizes = threshold,
              size_unit = "mm",
              interpolation_scale = interpolation_scale,
              extrapolate = "warn_linear"
            ),
            error = function(err) NULL
          )
          if (is.null(extrapolated_lookup)) {
            unresolved_seen <- TRUE
            if (unresolved == "error") {
              stop("Required fraction thresholds could not be resolved.", call. = FALSE)
            }
            rows[[row_id]] <- tibble::tibble(
              sample_id = sample_id,
              threshold_mm = threshold,
              threshold_um = mm_to_um(threshold),
              percent_finer = NA_real_,
              resolved = FALSE
            )
          } else {
            rows[[row_id]] <- tibble::tibble(
              sample_id = sample_id,
              threshold_mm = threshold,
              threshold_um = mm_to_um(threshold),
              percent_finer = extrapolated_lookup$percent_finer[1],
              resolved = TRUE
            )
          }
        }
      } else if (threshold > max_mm && !threshold_has_equivalent) {
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_mm = threshold,
          threshold_um = mm_to_um(threshold),
          percent_finer = 100,
          resolved = TRUE
        )
      } else if (is.null(resolved_lookup)) {
        unresolved_seen <- TRUE
        if (unresolved == "error") {
          stop("Required fraction thresholds could not be resolved.", call. = FALSE)
        }
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_mm = threshold,
          threshold_um = mm_to_um(threshold),
          percent_finer = NA_real_,
          resolved = FALSE
        )
      } else {
        match_idx <- which(resolved_lookup$threshold_mm == threshold)[1]
        rows[[row_id]] <- tibble::tibble(
          sample_id = sample_id,
          threshold_mm = resolved_lookup$threshold_mm[match_idx],
          threshold_um = resolved_lookup$threshold_um[match_idx],
          percent_finer = resolved_lookup$percent_finer[match_idx],
          resolved = TRUE
        )
      }
      row_id <- row_id + 1
    }
  }

  if (unresolved_seen) {
    warning(
      "Some required fraction thresholds could not be resolved; affected components are returned as NA.",
      call. = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

lookup_by_sample <- function(lookup) {
  split(lookup, lookup$sample_id, drop = TRUE)
}

lookup_threshold <- function(lookup_groups, sample_id, threshold) {
  group <- lookup_groups[[sample_id]]
  if (is.null(group)) {
    return(list(value = NA_real_, resolved = FALSE))
  }
  match_idx <- which(group$threshold_mm == threshold)[1]
  if (is.na(match_idx)) {
    return(list(value = NA_real_, resolved = FALSE))
  }
  list(value = group$percent_finer[match_idx], resolved = group$resolved[match_idx])
}

component_percent <- function(component, lookup, sample_id) {
  lower <- component$lower_mm
  upper <- component$upper_mm

  lower_value <- 0
  upper_value <- 100
  lower_resolved <- TRUE
  upper_resolved <- TRUE

  if (lower > 0) {
    lower_lookup <- lookup_threshold(lookup, sample_id, lower)
    lower_value <- lower_lookup$value
    lower_resolved <- lower_lookup$resolved
  }

  if (is.finite(upper)) {
    upper_lookup <- lookup_threshold(lookup, sample_id, upper)
    upper_value <- upper_lookup$value
    upper_resolved <- upper_lookup$resolved
  }

  resolved <- lower_resolved && upper_resolved
  percent <- if (resolved) upper_value - lower_value else NA_real_

  list(percent = percent, resolved = resolved)
}

fractions_one_sample <- function(sample_id, components, lookup, scheme, normalize, interpolation_scale) {
  rows <- lapply(seq_len(nrow(components)), function(i) {
    comp_row <- components[i, ]
    fraction <- component_percent(comp_row, lookup, sample_id)
    tibble::tibble(
      sample_id = sample_id,
      scheme = scheme,
      component = comp_row$component,
      lower_mm = comp_row$lower_mm,
      upper_mm = comp_row$upper_mm,
      lower_um = comp_row$lower_um,
      upper_um = comp_row$upper_um,
      percent = fraction$percent,
      normalize = normalize,
      interpolation_scale = interpolation_scale,
      resolved = fraction$resolved
    )
  })

  out <- do.call(rbind, rows)

  if (normalize == "fine_earth") {
    gravel <- out$percent[out$component == "gravel"][1]
    denominator <- 100 - gravel
    out <- out[out$component != "gravel", ]
    if (is.na(denominator) || denominator <= 0) {
      out$percent <- NA_real_
      out$resolved <- FALSE
    } else {
      out$percent <- out$percent / denominator * 100
    }
  }

  out
}

#' Calculate grain-size fraction percentages
#'
#' `gs_fractions()` calculates sediment or soil fraction percentages using a
#' named built-in particle-size scheme. Schemes are treated as complete,
#' non-overlapping particle-size partitions. Fractions are calculated from
#' cumulative percent-finer values at scheme thresholds by calling
#' `gs_percent_finer()` for thresholds inside the observed finite size range.
#'
#' Scheme thresholds do not need to match observed grain-size boundaries. When
#' thresholds such as 0.002, 0.020, 0.050, 0.060, or 0.063 mm are bracketed by finite class
#' boundaries, percent-finer values are interpolated on the cumulative curve.
#' Fraction and texture functions automatically use the normalized particle-size
#' scale from `gsd_tbl`; users do not need to specify millimetres or
#' micrometres after import.
#' Thresholds above the largest observed finite boundary resolve to 100 percent
#' finer. Thresholds below the smallest observed finite boundary resolve to
#' 0 percent finer **only when the excluded open-lower (pan) class carries no
#' retained mass** - in that case there is genuinely nothing finer than the
#' threshold, and 0 percent is exact, not an assumption. When the pan class
#' does carry retained mass, the true value below the smallest observed
#' boundary is not derivable from the data, and this now follows the same
#' `extrapolate` policy `gs_percent_finer()` uses for the identical
#' situation: `extrapolate = "error"` (the default) throws, and
#' `extrapolate = "warn_linear"` resolves a linearly-extrapolated value with
#' a warning. Earlier versions of this function returned a confident 0
#' percent unconditionally in this case regardless of pan mass - this was a
#' silent-assumption gap, corrected in this version (see
#' `dev-notes/AUDIT_LOG.md`'s "Root-cause: gs_fractions() below-finest-
#' boundary behavior" entry for the full investigation this fix implements).
#' `NA` is reserved for thresholds that are genuinely unresolved inside the
#' finite observed size range (governed by `unresolved`, separately from
#' `extrapolate`). Fraction schemes do not extrapolate unless
#' `extrapolate = "warn_linear"` is passed explicitly.
#'
#' Before applying the above range logic, a requested threshold is first
#' checked against a small, explicit table of known nominal sieve-mesh
#' equivalences (see `nominal_sieve_equivalence_groups_mm()`) - currently one
#' group, `{0.0625, 0.063}` mm, reflecting that no sieve manufacturer cuts a
#' 0.0625 mm (1/16 mm, the Udden-Wentworth phi-scale theoretical boundary
#' used by `wentworth_major`/`wentworth_detailed`) mesh: sieves certified
#' near this size under ISO 3310-1, ASTM E11, or DIN 4188 are labelled
#' 0.063 mm (the value `gravel_sand_mud`/`gradistat`/`germany_63` use). If a
#' sample's own finite boundary is a nominal-equivalence match for the
#' requested threshold, the threshold resolves directly from that
#' boundary's real value - not as an extrapolation, and not via the pan-mass
#' logic above. This equivalence match only rescues thresholds that would
#' otherwise be unresolved/extrapolated; when a threshold is already
#' resolvable by real interpolation between two distinct measured
#' boundaries (e.g. a sample with genuine finer-than-63μm data), real
#' interpolated data governs and the equivalence table has no effect. Only
#' the one listed group is ever treated as equivalent - unrelated boundaries
#' (e.g. USDA's 0.05 mm) are never affected.
#'
#' Fraction thresholds interpolate using `gs_percent_finer()`'s size-as-`x`
#' direction, so the tied-cumulative-value scenario that `gs_d_values()`
#' resolves deterministically (see its documentation) cannot occur here.
#'
#' @param x A valid `gsd_tbl` object.
#' @param scheme Built-in fraction scheme name.
#' @param normalize Normalization mode. `"none"` returns whole-sample
#'   percentages. `"fine_earth"` requires a scheme with a `gravel` component,
#'   excludes gravel rows, and normalizes the remaining non-gravel fractions
#'   against the non-gravel total.
#' @param interpolation_scale Interpolation scale passed to `gs_percent_finer()`.
#' @param unresolved Behavior when required thresholds cannot be calculated.
#'   `"warn_na"` warns and returns `NA` for affected components. `"error"`
#'   throws an error.
#' @param extrapolate Extrapolation behavior passed to `gs_percent_finer()`.
#'   The default `"error"` avoids silent extrapolation into open-ended terminal
#'   classes.
#'
#' @return A tibble with one row per sample and scheme component.
#' @export
gs_fractions <- function(x,
                         scheme = "wentworth_major",
                         normalize = c("none", "fine_earth"),
                         interpolation_scale = "phi",
                         unresolved = c("warn_na", "error"),
                         extrapolate = "error") {
  validate_gsd_tbl(x)
  scheme <- .validate_fraction_scheme(scheme)
  normalize <- match.arg(normalize)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  unresolved <- match.arg(unresolved)
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  .validate_fraction_normalize_scheme(scheme, normalize)
  components <- scheme_components(scheme)
  thresholds <- required_fraction_thresholds(components)
  lookup <- percent_finer_lookup(
    x,
    thresholds_mm = thresholds,
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate,
    unresolved = unresolved
  )

  sample_ids <- unique(as.character(x$sample_id))
  lookup_groups <- lookup_by_sample(lookup)
  out <- lapply(
    sample_ids,
    fractions_one_sample,
    components = components,
    lookup = lookup_groups,
    scheme = scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale
  )
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Calculate grain-size fraction percentages in wide form
#'
#' `gs_fractions_wide()` is a convenience wrapper around `gs_fractions()` that
#' returns one row per sample with one percentage column per fraction component.
#' See `gs_fractions()`'s Details for the nominal sieve-mesh equivalence table
#' and the pan-mass-aware below-boundary resolution logic this wrapper
#' inherits unchanged.
#'
#' @inheritParams gs_fractions
#'
#' @return A tibble with one row per sample and component percentage columns.
#' @export
gs_fractions_wide <- function(x,
                              scheme = "wentworth_major",
                              normalize = c("none", "fine_earth"),
                              interpolation_scale = "phi",
                              unresolved = c("warn_na", "error"),
                              extrapolate = "error") {
  fractions <- gs_fractions(
    x,
    scheme = scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale,
    unresolved = unresolved,
    extrapolate = extrapolate
  )
  sample_ids <- unique(fractions$sample_id)
  components <- unique(fractions$component)
  out <- tibble::tibble(sample_id = sample_ids)

  for (component in components) {
    values <- fractions$percent[fractions$component == component]
    names(values) <- fractions$sample_id[fractions$component == component]
    out[[paste0(component, "_percent")]] <- unname(values[out$sample_id])
  }

  out
}
