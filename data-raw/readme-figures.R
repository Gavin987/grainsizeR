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

wide_fractions <- suppressWarnings(gs_fractions_wide(wide, scheme = "gradistat"))
wide_gsm <- data.frame(
  sample_id = wide_fractions$sample_id,
  gravel = wide_fractions$gravel_percent,
  sand = wide_fractions$sand_percent,
  mud = wide_fractions$mud_percent,
  stringsAsFactors = FALSE
)
wide_gsm <- wide_gsm[stats::complete.cases(wide_gsm[c("gravel", "sand", "mud")]), ]

long_usda <- suppressWarnings(gs_fractions_wide(
  long,
  scheme = "usda_tt",
  extrapolate = "warn_linear"
))
long_ssc <- data.frame(
  sample_id = long_usda$sample_id,
  sand = long_usda$sand_percent,
  silt = long_usda$silt_percent,
  clay = long_usda$clay_percent,
  stringsAsFactors = FALSE
)
long_ssc <- long_ssc[stats::complete.cases(long_ssc[c("sand", "silt", "clay")]), ]

save_readme_plot(
  plot_distribution(wide, sample_id = wide_samples, type = "line"),
  "readme-wide-distribution.png"
)

save_readme_plot(
  plot_cumulative(
    wide,
    sample_id = wide_samples,
    show_percentiles = c(10, 50, 90),
    extrapolate = "warn_linear"
  ),
  "readme-wide-cumulative.png"
)

save_readme_plot(
  plot_fractions(wide, scheme = "gradistat", sample_id = wide_samples),
  "readme-wide-fractions.png"
)

save_readme_plot(
  plot_texture_ternary(
    wide_gsm[wide_gsm$sample_id %in% wide_samples, ],
    scheme = "gradistat",
    basis = "gravel_sand_mud",
    point_id = "sample_id"
  ),
  "readme-gradistat-ternary.png",
  width = 6,
  height = 5.2
)

save_readme_plot(
  suppressWarnings(plot_texture_ternary(long, scheme = "usda_tt", sample_id = long_samples)),
  "readme-usda-ternary.png",
  width = 6,
  height = 5.2
)
