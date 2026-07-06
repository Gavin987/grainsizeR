if (requireNamespace("devtools", quietly = TRUE) && file.exists("DESCRIPTION")) {
  devtools::load_all(quiet = TRUE)
} else {
  library(grainsizeR)
}

example_path <- function(filename) {
  source_path <- file.path("inst", "extdata", filename)
  if (file.exists(source_path)) {
    return(source_path)
  }

  installed_path <- system.file("extdata", filename, package = "grainsizeR")
  if (!nzchar(installed_path)) {
    stop("Could not locate bundled example file: ", filename, call. = FALSE)
  }
  installed_path
}

readme_width_px <- 1000
readme_dpi <- 144

save_readme_plot <- function(plot, filename, width = 7, height = 4.8) {
  aspect_ratio <- height / width
  ggplot2::ggsave(
    filename = file.path("man", "figures", filename),
    plot = plot,
    width = readme_width_px / readme_dpi,
    height = readme_width_px * aspect_ratio / readme_dpi,
    units = "in",
    dpi = readme_dpi
  )
}

dir.create(file.path("man", "figures"), recursive = TRUE, showWarnings = FALSE)

wide_path <- example_path("grain.wide.csv")
long_path <- example_path("grain.long.csv")

wide <- read_gsd(wide_path, format = "wide")
long <- read_gsd(long_path)

wide_samples <- utils::head(unique(wide$sample_id), 10)
wide_plot_sample <- wide_samples[1]

wide_gsm <- suppressWarnings(gs_fractions(wide, scheme = "gravel_sand_mud"))

# grain.long.csv has no real data below 63um for any sample; USDA's 2um
# clay boundary is therefore resolved via explicit linear extrapolation
# (extrapolate = "warn_linear", with a warning) rather than the pre-fix
# silent zero. For the 9 samples with some finer resolution (~8-13um),
# this is a small, plausible overshoot past the natural 0% clay boundary
# (at most ~5.4 percentage points) - clipped to 0 and the difference
# proportionally redistributed across sand/silt so the total still sums
# to exactly 100 (required by the USDA classifier's own tolerance). For
# the remaining 21 sieve-only samples (finest boundary 63um), the same
# extrapolation is a ~63um-to-2um gap and produces wildly unreliable
# values (e.g. clay to -132%) - these are excluded as unreliable
# extrapolations, not silently shown.
long_usda_fractions <- suppressWarnings(gs_fractions_wide(
  long,
  scheme = "usda",
  normalize = "fine_earth",
  unresolved = "warn_na",
  extrapolate = "warn_linear"
))
usda_component_cols <- as.matrix(long_usda_fractions[c("sand_percent", "silt_percent", "clay_percent")])
usda_clipped <- pmax(usda_component_cols, 0)
usda_clip_correction <- rowSums(usda_component_cols) - rowSums(usda_clipped)
usda_small_correction <- stats::complete.cases(usda_component_cols) &
  apply(usda_component_cols, 1, function(row) all(is.finite(row))) &
  (-usda_clip_correction) <= 10
usda_renormalized <- usda_clipped / rowSums(usda_clipped) * 100

usda_points <- long_usda_fractions
usda_points[c("sand_percent", "silt_percent", "clay_percent")] <- usda_renormalized
usda_points <- usda_points[usda_small_correction, ]

save_readme_plot(
  plot_distribution(wide, sample_id = wide_plot_sample, cumulative = TRUE, particle_unit = "mm"),
  "readme-wide-distribution.png"
)

save_readme_plot(
  plot_cumulative(
    wide,
    sample_id = wide_plot_sample,
    particle_unit = "mm",
    show_percentiles = TRUE
  ),
  "readme-wide-cumulative.png"
)

save_readme_plot(
  plot_fractions(
    wide,
    scheme = "gravel_sand_mud",
    sample_id = wide_samples,
    fill_palette = "YlOrBr"
  ),
  "readme-wide-fractions.png"
)

save_readme_plot(
  plot_texture_ternary(
    wide_gsm[wide_gsm$sample_id %in% wide_samples, ],
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id",
    show_sample_labels = FALSE,
    class_label_size = 2.1
  ),
  "readme-gradistat-ternary.png",
  width = 6,
  height = 5.2
)

save_readme_plot(
  plot_texture_ternary(
    usda_points,
    scheme = "usda",
    point_id = "sample_id",
    show_sample_labels = FALSE,
    class_label_size = 2.1
  ),
  "readme-usda-ternary.png",
  width = 6,
  height = 5.2
)
