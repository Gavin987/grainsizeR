texture_source_audit_rows <- function() {
  tibble::tibble(
    scheme = c(
      "usda",
      "hypres",
      "isss",
      "uk_ssew",
      "gradistat",
      "australia_20",
      "germany_63",
      "sweden_60",
      "canada_50",
      "belgium_50",
      "fr_aisne",
      "fr_geppa",
      "wrb",
      "fao_guidelines",
      "iso_25177",
      "din_19682",
      "din_4220",
      "bodenschaetzung",
      "referentiel_pedologique",
      "bze_wald_ii",
      "forstliche_standortsaufnahme"
    ),
    scheme_name = c(
      "USDA texture triangle",
      "HYPRES texture classes",
      "International Society of Soil Science texture classes",
      "UK SSEW texture classes",
      "GRADISTAT texture classes",
      "Australia 20 um texture boundaries",
      "Germany 63 um texture boundaries",
      "Sweden 60 um texture boundaries",
      "Canada 50 um texture boundaries",
      "Belgium 50 um texture boundaries",
      "French Aisne texture classes",
      "French GEPPA texture classes",
      "World Reference Base for Soil Resources",
      "FAO Guidelines for Soil Description",
      "ISO 25177 field soil description",
      "DIN 19682 field investigation",
      "DIN 4220 pedologic site assessment",
      "Bodenschaetzung / Guidelines Soil Assessment",
      "Referentiel Pedologique",
      "BZE Wald II",
      "Forstliche Standortsaufnahme"
    ),
    domain = c(
      rep("soil texture", 4),
      "sedimentology",
      rep("soil texture", 7),
      "soil_classification_reference",
      "field_soil_description",
      "field_soil_description",
      "field_soil_description",
      "field_soil_description",
      "soil_classification_reference",
      "soil_classification_reference",
      "field_soil_description",
      "field_soil_description"
    ),
    particle_size_system = c(
      "usda",
      "hypres",
      "isss",
      "uk_ssew",
      "gradistat",
      "australia_20",
      "germany_63",
      "sweden_60",
      "canada_50",
      "belgium_50",
      "fr_aisne",
      "fr_geppa",
      rep("not_applicable", 9)
    ),
    clay_upper_um = c(2, 2, 2, 2, 4, 2, 2, 2, 2, 2, 2, 2, rep(NA_real_, 9)),
    silt_upper_um = c(50, 50, 20, 60, 63, 20, 63, 60, 50, 50, 50, 50, rep(NA_real_, 9)),
    sand_upper_um = c(rep(2000, 12), rep(NA_real_, 9)),
    left_component = c(rep("sand", 12), rep(NA_character_, 9)),
    right_component = c(rep("silt", 12), rep(NA_character_, 9)),
    top_component = c(rep("clay", 4), "clay_or_mud", rep("clay", 7), rep(NA_character_, 9)),
    texture_polygon_status = c(
      "coordinates_pending",
      "coordinates_pending",
      "coordinates_pending",
      "coordinates_pending",
      "source_audit",
      "coordinates_pending",
      "source_audit",
      "not_planned",
      "coordinates_pending",
      "coordinates_pending",
      "coordinates_pending",
      "coordinates_pending",
      rep("not_planned", 9)
    ),
    fraction_scheme_status = c(
      "implemented",
      "implemented",
      "implemented",
      "implemented",
      "implemented",
      "implemented",
      "implemented",
      "implemented",
      "planned",
      "planned",
      "planned",
      "planned",
      rep("not_applicable", 9)
    ),
    primary_source_status = c(
      rep("primary_source_candidates_identified", 4),
      rep("needs_verification", 5),
      "primary_source_candidates_identified",
      rep("needs_verification", 2),
      rep("reference_only", 9)
    ),
    primary_source_short = c(
      "USDA / NRCS Soil Survey Manual; NRCS Soil Texture Calculator",
      "HYPRES project documentation; European Soil Map documentation",
      "IUSS / former ISSS documentation; Verheye and Ameryckx source candidates",
      "Soil Survey of England and Wales; Defra or Rural Development Service Technical Advice Note 52",
      "Blott and Pye GRADISTAT paper or manual; Folk or Wentworth sedimentological references",
      "Australian soil survey or soil science documentation; Minasny and McBratney source candidate",
      "German Bodenkundliche Kartieranleitung; German SEA 1974 or TGL 1985 variants to verify",
      "Swedish particle-size boundary source to be verified",
      "Canadian Soil Information System / CanSIS documentation; Canadian soil survey references",
      "Belgian soil map or soil survey documentation; Defourny or Van Bossuyt candidates",
      "Baize and Jabiol; Jamagne; Aisne agricultural extension source candidates",
      "GEPPA documentation; Baize and Jabiol; sols-de-bretagne source candidates",
      "World Reference Base for Soil Resources",
      "FAO Guidelines for Soil Description",
      "ISO 25177",
      "DIN 19682 series",
      "DIN 4220",
      "Bodenschaetzung / Guidelines Soil Assessment",
      "Referentiel Pedologique",
      "BZE Wald II",
      "Forstliche Standortsaufnahme"
    ),
    primary_source_full = rep(NA_character_, 21),
    secondary_source_note = c(
      "Soil Texture Wizard points to the Soil Survey Manual as a source clue; no data were copied.",
      "Secondary references may help identify HYPRES and European Soil Map sources; no polygon data have been copied.",
      "Secondary references may help distinguish the particle-size system from any texture triangle; no polygon data have been copied.",
      "Secondary references may help identify UK SSEW or Defra source candidates; no polygon data have been copied.",
      "Secondary references may help identify GRADISTAT grouping rules; no polygon data have been copied.",
      "Secondary references may help identify Australian source candidates; no polygon data have been copied.",
      "Secondary references may help identify German source candidates and variants; no polygon data have been copied.",
      "Boundary system included for fraction calculations; no specific Swedish texture triangle source is currently planned.",
      "Secondary references may help identify CanSIS or Canadian soil survey sources; no polygon data have been copied.",
      "Secondary references may help identify Belgian source candidates; no polygon data have been copied.",
      "Secondary references may help identify French Aisne source candidates; no polygon data have been copied.",
      "Secondary references may help identify French GEPPA source candidates; no polygon data have been copied.",
      "ZALF overview lists WRB as a broader soil classification reference.",
      "ZALF overview lists FAO Guidelines as a broader field soil description reference.",
      "ZALF overview lists ISO 25177 as a broader field soil description reference.",
      "ZALF overview lists DIN 19682 as field investigation guidance.",
      "ZALF overview lists DIN 4220 as pedologic site assessment guidance.",
      "ZALF overview lists soil assessment guidance as broader assessment context.",
      "ZALF overview lists Referentiel Pedologique as a broader soil classification reference.",
      "ZALF overview lists BZE Wald II as forest soil survey context.",
      "ZALF overview lists Forstliche Standortsaufnahme as forest site survey context."
    ),
    implementation_note = c(
      "Particle-size fraction scheme implemented; texture polygon coordinates pending independent reconstruction from primary sources.",
      "HYPRES is implemented only as a fraction scheme for now; texture polygon coordinates are pending primary-source reconstruction.",
      "ISSS fraction boundaries are implemented; any texture triangle requires separate source review and reconstruction.",
      "UK SSEW fraction boundaries are implemented; texture polygon coordinates are pending primary-source reconstruction.",
      "GRADISTAT may require grouping rules different from standard soil texture ternary diagrams; source rules need review.",
      "Australia 20 um boundaries are implemented as a fraction scheme; polygon coordinates are pending source verification.",
      "Germany 63 currently denotes a particle-size boundary system, not a single implemented polygon system.",
      "Sweden 60 is currently a particle-size boundary system, not a planned built-in polygon system.",
      "Canada 50 um boundaries are planned for source audit; texture polygon coordinates are pending source verification.",
      "Belgium 50 um boundaries are planned for source audit; texture polygon coordinates are pending source verification.",
      "French Aisne texture polygon coordinates are pending source verification and independent reconstruction.",
      "French GEPPA texture polygon coordinates are pending source verification and independent reconstruction.",
      "Reference-only soil classification system; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only field soil description guideline; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only field soil description standard; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only field investigation standard; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only pedologic site assessment standard; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only soil assessment framework; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only soil classification system; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only forest soil survey standard; not implemented as a fraction scheme or texture polygon dataset.",
      "Reference-only forest site survey standard; not implemented as a fraction scheme or texture polygon dataset."
    ),
    include_in_package = c(
      rep(TRUE, 7),
      FALSE,
      rep(TRUE, 4),
      rep(TRUE, 9)
    )
  )
}

#' Inspect the texture source audit registry
#'
#' `texture_source_audit()` returns a source-audit registry for planned texture
#' and particle-size systems. It is not a texture polygon dataset and does not
#' contain polygon coordinates, class vertices, or class tables.
#'
#' `primary_source_status = "needs_verification"` means that candidate sources
#' have not yet been reviewed as package-ready primary documentation. Future
#' built-in polygon datasets should be reconstructed from original official or
#' academic sources, cited, reviewed, and tested before implementation.
#'
#' @return A tibble describing source-audit status for texture and
#'   particle-size systems.
#' @export
texture_source_audit <- function() {
  texture_source_audit_rows()
}
