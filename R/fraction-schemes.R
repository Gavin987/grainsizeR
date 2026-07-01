#' List built-in grain-size fraction schemes
#'
#' `gs_fraction_schemes()` returns the particle-size component definitions used
#' by `gs_fractions()`. Bounds are returned in millimetres and micrometres.
#' Fraction calculations use the millimetre bounds after normalizing `gsd_tbl`
#' sizes from their internal micrometre storage. Each scheme is represented as
#' a complete, non-overlapping particle-size partition. Lower bounds are
#' inclusive for interpretation, and upper bounds define the cumulative
#' threshold used to calculate each fraction.
#' `gravel_sand_mud` is an explicit public alias of `wentworth_major`; both
#' schemes use gravel, sand, and mud components with boundaries at 2000 and
#' 62.5 micrometres. GRADISTAT ternary examples use
#' `scheme = "gravel_sand_mud"` because it makes the required ternary
#' components explicit, while `wentworth_major` remains available for users who
#' prefer the Wentworth naming.
#'
#' @return A tibble describing built-in fraction schemes.
#' @export
gs_fraction_schemes <- function() {
  systems <- particle_size_systems()
  wentworth_major <- fraction_rows("wentworth_major", c("gravel", "sand", "mud"), c(2000, 62.5, 0), c(Inf, 2000, 62.5))
  rows <- list(
    wentworth_major,
    fraction_scheme_alias(wentworth_major, "gravel_sand_mud"),
    fraction_rows(
      "wentworth_detailed",
      c(
        "coarse_gravel", "medium_gravel", "fine_gravel", "very_fine_gravel",
        "very_coarse_sand", "coarse_sand", "medium_sand", "fine_sand", "very_fine_sand",
        "very_coarse_silt", "coarse_silt", "medium_silt", "fine_silt", "very_fine_silt",
        "clay"
      ),
      c(16000, 8000, 4000, 2000, 1000, 500, 250, 125, 62.5, 31.25, 15.625, 7.8125, 3.90625, 2, 0),
      c(Inf, 16000, 8000, 4000, 2000, 1000, 500, 250, 125, 62.5, 31.25, 15.625, 7.8125, 3.90625, 2),
      component_type = rep("detailed", 15)
    ),
    fraction_rows_from_system(systems, "gradistat"),
    fraction_rows_from_system(systems, "usda_tt"),
    fraction_rows_from_system(systems, "isss"),
    fraction_rows_from_system(systems, "uk_ssew"),
    fraction_rows_from_system(systems, "hypres"),
    fraction_rows_from_system(systems, "germany_63"),
    fraction_rows_from_system(systems, "australia_20"),
    fraction_rows_from_system(systems, "sweden_60")
  )

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

fraction_scheme_alias <- function(template, scheme) {
  out <- template
  out$scheme <- scheme
  out$description <- paste(fraction_scheme_label(scheme), out$component, "fraction")
  out
}

fraction_rows <- function(scheme, component, lower_um, upper_um, component_type = NULL) {
  if (is.null(component_type)) {
    component_type <- rep("major", length(component))
  }

  description <- paste(fraction_scheme_label(scheme), component, "fraction")

  tibble::tibble(
    scheme = scheme,
    component = component,
    order = seq_along(component),
    lower_mm = um_to_mm(lower_um),
    upper_mm = um_to_mm(upper_um),
    lower_um = lower_um,
    upper_um = upper_um,
    component_type = component_type,
    description = description
  )
}

fraction_rows_from_system <- function(systems, system_id, include_mud = FALSE) {
  system <- systems[systems$system_id == system_id, ]
  if (nrow(system) != 1) {
    stop("Unknown particle-size system: ", system_id, call. = FALSE)
  }

  component <- c("gravel", "sand", "silt", "clay")
  lower_um <- c(
    system$gravel_lower_um,
    system$silt_upper_um,
    system$clay_upper_um,
    0
  )
  upper_um <- c(
    Inf,
    system$sand_upper_um,
    system$silt_upper_um,
    system$clay_upper_um
  )
  component_type <- rep("major", 4)

  if (include_mud) {
    component <- c(component, "mud")
    lower_um <- c(lower_um, 0)
    upper_um <- c(upper_um, system$silt_upper_um)
    component_type <- c(component_type, "aggregate")
  }

  fraction_rows(
    scheme = system_id,
    component = component,
    lower_um = lower_um,
    upper_um = upper_um,
    component_type = component_type
  )
}

fraction_scheme_label <- function(scheme) {
  labels <- c(
    wentworth_major = "Wentworth major",
    gravel_sand_mud = "Gravel-sand-mud",
    wentworth_detailed = "Wentworth detailed",
    gradistat = "GRADISTAT",
    usda_tt = "USDA texture triangle",
    isss = "International Society of Soil Science",
    uk_ssew = "UK SSEW",
    hypres = "HYPRES",
    germany_63 = "Germany 63 um",
    australia_20 = "Australia 20 um",
    sweden_60 = "Sweden 60 um"
  )
  unname(labels[[scheme]])
}
