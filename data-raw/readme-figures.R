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

save_readme_plot <- function(plot, filename, width = 7, height = 4.8) {
  ggplot2::ggsave(
    filename = file.path("man", "figures", filename),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 144
  )
}

dir.create(file.path("man", "figures"), recursive = TRUE, showWarnings = FALSE)

wide_path <- example_path("grain.wide.csv")
long_path <- example_path("grain.long.csv")

wide <- read_gsd(wide_path, format = "wide")
long <- read_gsd(long_path)

wide_samples <- c("WN1_upper", "WN2_upper", "WN3_upper", "WS1_upper")
long_samples <- c("WN1_upper", "WN2_upper", "WN3_upper", "WS1_upper")
wide_plot_sample <- "WN1_upper"

wide_fractions <- suppressWarnings(gs_fractions_wide(wide, scheme = "gradistat"))
wide_gsm <- data.frame(
  sample_id = wide_fractions$sample_id,
  gravel = wide_fractions$gravel_percent,
  sand = wide_fractions$sand_percent,
  mud = wide_fractions$mud_percent,
  stringsAsFactors = FALSE
)
wide_gsm <- wide_gsm[stats::complete.cases(wide_gsm[c("gravel", "sand", "mud")]), ]

usda_demo <- data.frame(
  sample_id = c("demo: sand", "demo: loam", "demo: clay"),
  sand = c(92, 42, 22),
  silt = c(5, 38, 22),
  clay = c(3, 20, 56),
  stringsAsFactors = FALSE
)

long_usda_fractions <- suppressWarnings(gs_fractions_wide(
  long,
  scheme = "usda_tt",
  normalize = "none",
  unresolved = "warn_na",
  extrapolate = "warn_linear"
))
long_usda <- data.frame(
  sample_id = paste0("example: ", long_usda_fractions$sample_id),
  sand = long_usda_fractions$sand_percent,
  silt = long_usda_fractions$silt_percent,
  clay = long_usda_fractions$clay_percent,
  stringsAsFactors = FALSE
)
long_usda_valid <- stats::complete.cases(long_usda[c("sand", "silt", "clay")]) &
  rowSums(long_usda[c("sand", "silt", "clay")] >= 0 & long_usda[c("sand", "silt", "clay")] <= 100) == 3 &
  abs(rowSums(long_usda[c("sand", "silt", "clay")]) - 100) < 1e-6
usda_points <- rbind(usda_demo, long_usda[long_usda_valid, ])

save_readme_plot(
  plot_distribution(wide, sample_id = wide_plot_sample, cumulative = TRUE, particle_unit = "mm"),
  "readme-wide-distribution.png"
)

save_readme_plot(
  plot_cumulative(
    wide,
    sample_id = wide_plot_sample,
    particle_unit = "mm",
    show_percentiles = c(10, 50, 90),
    extrapolate = "warn_linear"
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
    scheme = "usda_tt",
    point_id = "sample_id",
    show_sample_labels = FALSE,
    class_label_size = 2.1
  ),
  "readme-usda-ternary.png",
  width = 6,
  height = 5.2
)
