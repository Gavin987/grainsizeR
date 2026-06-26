#' grainsizeR: sediment grain-size analysis tools
#'
#' grainsizeR provides tools for sediment grain-size analysis in R. It reads
#' retained grain-size distributions, stores them as validated `gsd_tbl`
#' objects, calculates boundary-based grain-size statistics, and creates common
#' plots for distribution, cumulative, fraction, and ternary texture workflows.
#'
#' Input data can be supplied in long format, with one row per sample and size
#' class, or in wide format, with size classes in rows and samples in columns.
#' Values may be retained proportions, retained percentages, or weights that
#' are normalized within each sample.
#'
#' In grainsizeR, `D_p` is the grain size at which `p` percent of the sample is
#' finer. For example, `D50` is the median grain size on the percent-finer
#' curve.
#'
#' A typical workflow is:
#'
#' 1. Read data with `read_gsd()` or `read_gsd_wide()`.
#' 2. Inspect and validate the resulting `gsd_tbl`.
#' 3. Calculate D-values with `gs_d_values()`.
#' 4. Calculate additional grain-size indices with
#'    `gs_grain_size_indices()`.
#' 5. Calculate Folk and Ward statistics with `gs_folk_ward()`.
#' 6. Optionally calculate moments with explicit open-end handling using
#'    `gs_moments()`.
#' 7. Calculate fractions with `gs_fractions()` or `gs_fractions_wide()`.
#' 8. Plot results with `plot_distribution()`, `plot_cumulative()`,
#'    `plot_fractions()`, and `plot_texture_ternary()`.
#' 9. Optionally classify samples with user-supplied texture polygons.
#'
#' Open-ended terminal classes are not silently treated as bounded intervals.
#' Calculations that would require values inside open tails require explicit
#' extrapolation or unresolved-value handling. Built-in official texture polygon
#' datasets are not bundled yet. The package does not implement civil
#' engineering classification systems.
#'
#' @keywords internal
"_PACKAGE"
