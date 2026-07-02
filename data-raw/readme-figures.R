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

long_usda_fractions <- suppressWarnings(gs_fractions_wide(
  long,
  scheme = "usda",
  normalize = "fine_earth",
  unresolved = "warn_na",
  extrapolate = "warn_linear"
))
long_usda_valid <- stats::complete.cases(long_usda_fractions[c("sand_percent", "silt_percent", "clay_percent")]) &
  abs(rowSums(long_usda_fractions[c("sand_percent", "silt_percent", "clay_percent")]) - 100) < 1e-6
usda_points <- long_usda_fractions[long_usda_valid, ]

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
