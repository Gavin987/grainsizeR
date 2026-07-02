format_range_um <- function(lower, upper) {
  if (is.na(lower) || is.na(upper)) {
    return(NA_character_)
  }

  if (is.infinite(upper)) {
    return(paste0(">", lower, " um"))
  }

  paste0(lower, "-", upper, " um")
}

#' List built-in particle-size boundary systems
#'
#' `particle_size_systems()` returns source-aware metadata for particle-size
#' boundary systems used or planned by grainsizeR. These entries describe
#' particle-size boundaries only; they are not complete texture classification
#' systems and do not include texture-class polygon coordinates.
#'
#' @return A tibble describing particle-size boundary systems.
#' @export
particle_size_systems <- function() {
  system_id <- c(
    "wentworth_major",
    "gradistat",
    "usda",
    "isss",
    "uk_ssew",
    "hypres",
    "germany_63",
    "australia_20",
    "sweden_60"
  )
  system_name <- c(
    "Wentworth major fractions",
    "GRADISTAT particle-size boundaries",
    "USDA texture triangle particle-size boundaries",
    "International Society of Soil Science particle-size boundaries",
    "UK SSEW particle-size boundaries",
    "HYPRES particle-size boundaries",
    "Germany 63 um silt-sand boundary",
    "Australia 20 um silt-sand boundary",
    "Sweden 60 um silt-sand boundary"
  )
  country_or_region <- c(
    "International",
    "International",
    "United States",
    "International",
    "United Kingdom",
    "Europe",
    "Germany",
    "Australia",
    "Sweden"
  )
  domain <- c(
    "sedimentology",
    "sedimentology",
    rep("soil texture", 7)
  )
  clay_upper_um <- c(NA_real_, 4, 2, 2, 2, 2, 2, 2, 2)
  silt_upper_um <- c(NA_real_, 63, 50, 20, 60, 50, 63, 20, 60)
  sand_upper_um <- rep(2000, length(system_id))
  gravel_lower_um <- rep(2000, length(system_id))
  source_status <- c(
    rep("implemented", 5),
    rep("needs_primary_source_verification", 4)
  )
  source_reference <- c(
    "Wentworth major size classes",
    "GRADISTAT / Blott and Pye",
    "USDA texture triangle",
    "International Society of Soil Science",
    "UK SSEW / Defra",
    "HYPRES / European Soil Map",
    "German particle-size boundaries",
    "Australian particle-size boundaries",
    "Swedish particle-size boundaries"
  )
  notes <- c(
    "Major sediment fractions only; clay and silt are aggregated as mud.",
    "Boundary metadata only; texture polygons are not included.",
    "Boundary metadata only; texture polygons are planned separately.",
    "Boundary metadata only; texture polygons are planned separately.",
    "Boundary metadata only; texture polygons are planned separately.",
    "Boundary metadata only; texture polygons are planned separately.",
    "Boundary metadata only; primary source citation needs verification.",
    "Boundary metadata only; primary source citation needs verification.",
    "Boundary metadata only; primary source citation needs verification."
  )

  clay_range <- mapply(format_range_um, 0, clay_upper_um, USE.NAMES = FALSE)
  silt_lower <- clay_upper_um
  silt_range <- mapply(format_range_um, silt_lower, silt_upper_um, USE.NAMES = FALSE)
  sand_lower <- ifelse(is.na(silt_upper_um), 62.5, silt_upper_um)
  sand_range <- mapply(format_range_um, sand_lower, sand_upper_um, USE.NAMES = FALSE)
  gravel_range <- mapply(format_range_um, gravel_lower_um, Inf, USE.NAMES = FALSE)

  tibble::tibble(
    system_id = system_id,
    system_name = system_name,
    country_or_region = country_or_region,
    domain = domain,
    clay_upper_um = clay_upper_um,
    silt_upper_um = silt_upper_um,
    sand_upper_um = sand_upper_um,
    gravel_lower_um = gravel_lower_um,
    clay_range = clay_range,
    silt_range = silt_range,
    sand_range = sand_range,
    gravel_range = gravel_range,
    source_status = source_status,
    source_reference = source_reference,
    notes = notes
  )
}
