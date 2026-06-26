parse_d_parameters <- function(parameters) {
  d_tokens <- grep("^D[0-9]+(\\.[0-9]+)?$", parameters, value = TRUE)
  as.numeric(sub("^D", "", d_tokens))
}

parameter_method <- function(parameter) {
  if (grepl("^D[0-9]+(\\.[0-9]+)?_um$", parameter)) {
    "percentile"
  } else if (
    parameter %in% c(
      "D10", "D25", "D50", "D75", "D90", "d_value_unit",
      "D90_D10_ratio", "D90_minus_D10", "D75_D25_ratio",
      "D75_minus_D25", "D90_D10_log_ratio", "D75_D25_log_ratio"
    )
  ) {
    "d_spread"
  } else if (grepl("^mode[0-9]+_", parameter) || parameter == "sample_modality") {
    "modes"
  } else if (grepl("_description$", parameter) || grepl("^description_", parameter)) {
    "descriptors"
  } else if (grepl("^quality_", parameter) || grepl("_quality_status$", parameter)) {
    "quality"
  } else if (grepl("_percent$", parameter) && parameter != "fine_content_percent") {
    "fractions"
  } else if (
    grepl("_moment", parameter) ||
      parameter == "retained_percent_used" ||
      parameter %in% c("open_end_estimated", "open_end_omitted")
  ) {
    "moments"
  } else if (
    grepl("_fw", parameter) ||
      grepl("^D(5|16|25|50|75|84|95)_(um|phi)$", parameter) ||
      parameter == "mean_fw_um" ||
      parameter == "any_extrapolated"
  ) {
    "folk_ward"
  } else if (parameter == "interpolation_scale") {
    "metadata"
  } else {
    "indices"
  }
}

parameter_unit <- function(parameter) {
  if (
    grepl("^D[0-9]+(\\.[0-9]+)?_um$", parameter) ||
      parameter %in% c("D10", "D25", "D50", "D75", "D90", "mode1_size_um", "mode2_size_um", "mode3_size_um") ||
      parameter == "mean_fw_um" ||
      parameter == "mean_moment_um" ||
      parameter == "sd_moment_um" ||
      parameter == "fine_threshold_um"
  ) {
    "um"
  } else if (grepl("^mode[0-9]+_(size_mm|class_lower_mm|class_upper_mm)$", parameter)) {
    "mm"
  } else if (
    grepl("^D[0-9]+(\\.[0-9]+)?_phi$", parameter) ||
      grepl("_fw_phi$", parameter) ||
      parameter %in% c("mode1_phi", "mode2_phi", "mode3_phi") ||
      parameter == "mean_moment_phi" ||
      parameter == "sd_moment_phi"
  ) {
    "phi"
  } else if (parameter == "fine_content_percent" || parameter == "fine_equivalent" || grepl("_percent$", parameter)) {
    "percent"
  } else if (
    parameter == "interpolation_scale" ||
      parameter == "any_extrapolated" ||
      parameter == "d_value_unit" ||
      parameter == "sample_modality" ||
      grepl("_description$", parameter) ||
      grepl("^description_", parameter) ||
      grepl("^quality_", parameter) ||
      grepl("_quality_status$", parameter) ||
      parameter %in% c("open_end_estimated", "open_end_omitted")
  ) {
    NA_character_
  } else {
    "unitless"
  }
}

moments_for_parameters <- function(x, moments_method, moments_open_end) {
  moments <- gs_moments(
    x,
    method = moments_method,
    open_end = moments_open_end
  )

  if (moments_method == "logarithmic_phi") {
    out <- tibble::tibble(
      sample_id = moments$sample_id,
      mean_moment_phi = moments$mean_moment_phi,
      mean_moment_um = moments$mean_moment_um,
      sd_moment_phi = moments$sd_moment,
      skewness_moment = moments$skewness_moment,
      kurtosis_moment = moments$kurtosis_moment,
      retained_percent_used = moments$retained_percent_used,
      moments_open_end = moments$open_end,
      open_end_estimated = moments$open_end_estimated,
      open_end_omitted = moments$open_end_omitted
    )
  } else {
    out <- tibble::tibble(
      sample_id = moments$sample_id,
      mean_moment_um = moments$mean_moment_um,
      mean_moment_phi = moments$mean_moment_phi,
      sd_moment_um = moments$sd_moment,
      skewness_moment = moments$skewness_moment,
      kurtosis_moment = moments$kurtosis_moment,
      retained_percent_used = moments$retained_percent_used,
      moments_open_end = moments$open_end,
      open_end_estimated = moments$open_end_estimated,
      open_end_omitted = moments$open_end_omitted
    )
  }

  out
}

modes_for_parameters <- function(x, n_modes) {
  modes <- gs_modes(x, n_modes = n_modes)
  sample_ids <- unique(modes$sample_id)
  out <- tibble::tibble(sample_id = sample_ids)
  out$sample_modality <- modes$sample_modality[match(sample_ids, modes$sample_id)]

  fields <- c(
    "mode_size_mm", "mode_size_um", "mode_phi",
    "mode_class_lower_mm", "mode_class_upper_mm",
    "mode_percent", "mode_class_label", "is_open_interval", "mode_status"
  )

  for (rank in seq_len(n_modes)) {
    one <- modes[modes$mode_rank == rank, ]
    one <- one[match(sample_ids, one$sample_id), ]
    for (field in fields) {
      out[[paste0("mode", rank, "_", sub("^mode_", "", field))]] <- one[[field]]
    }
  }

  out
}

quality_for_parameters <- function(x,
                                   sediment_loss_percent,
                                   sediment_loss_warning_percent,
                                   fine_pan_info_percent,
                                   fine_pan_warning_percent) {
  flags <- gs_quality_flags(
    x,
    sediment_loss_percent = sediment_loss_percent,
    sediment_loss_warning_percent = sediment_loss_warning_percent,
    fine_pan_info_percent = fine_pan_info_percent,
    fine_pan_warning_percent = fine_pan_warning_percent
  )
  sample_ids <- unique(flags$sample_id)
  out <- tibble::tibble(sample_id = sample_ids)

  for (flag in unique(flags$quality_flag)) {
    one <- flags[flags$quality_flag == flag, ]
    one <- one[match(sample_ids, one$sample_id), ]
    out[[paste0(flag, "_quality_status")]] <- one$quality_status
    out[[paste0(flag, "_quality_message")]] <- one$quality_message
  }

  status_rank <- c(ok = 1L, not_evaluated = 2L, needs_additional_analysis = 3L, warning = 4L)
  out$quality_overall_status <- vapply(sample_ids, function(sample_id) {
    one <- flags[flags$sample_id == sample_id, ]
    one$quality_status[which.max(status_rank[one$quality_status])]
  }, character(1))

  out
}

parameters_to_long <- function(wide) {
  value_cols <- setdiff(names(wide), "sample_id")
  value_cols <- value_cols[vapply(wide[value_cols], function(x) is.numeric(x) || is.logical(x), logical(1))]
  rows <- lapply(value_cols, function(col) {
    tibble::tibble(
      sample_id = wide$sample_id,
      parameter = col,
      value = as.numeric(wide[[col]]),
      unit = parameter_unit(col),
      method = parameter_method(col)
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Summarize grain-size parameters
#'
#' `gs_parameters()` is a minimal user-facing summary interface for selected
#' D-values returned by `gs_d_values()`, additional grain-size indices returned
#' by `gs_grain_size_indices()`, GRADISTAT-style D-spread descriptors returned
#' by `gs_d_spread()`, Folk and Ward graphical statistics returned by
#' `gs_folk_ward()`, midpoint moment statistics returned by `gs_moments()`,
#' modal class descriptors returned by `gs_modes()`, and particle-size fractions
#' returned by `gs_fractions_wide()`. Optional descriptor and quality groups
#' add GRADISTAT-style printout terms and advisory quality flags.
#'
#' The function is useful for generating compact summary tables for reports.
#' It returns ordinary tabular output, so file export is intentionally left to
#' standard R workflows such as `write.csv()` or `saveRDS()`.
#'
#' @param x A valid `gsd_tbl` object.
#' @param parameters Character vector of parameters. Supported values are
#'   `"d_values"`, D-value tokens such as `"D10"`, `"D30"`, and `"D90"`,
#'   plus the aliases `"d_spread"`, `"indices"`, `"folk_ward"`, `"moments"`,
#'   `"modes"`, `"descriptors"`, `"quality"`, and `"fractions"`.
#'   `"engineering"` is accepted as a compatibility alias for `"indices"`.
#' @param output Output shape. `"wide"` returns one row per sample, while
#'   `"long"` returns parameter-value rows.
#' @param d_values Numeric vector of D-value percentiles used when
#'   `parameters` includes `"d_values"`.
#' @param interpolation_scale Interpolation scale passed to lower-level
#'   calculations.
#' @param extrapolate Extrapolation behavior passed to lower-level
#'   calculations.
#' @param d_spread_scale Metric reporting scale passed to `gs_d_spread()`.
#' @param fine_threshold_um Fine-content threshold in micrometers for
#'   grain-size index summaries.
#' @param moments_method Moment scale passed to `gs_moments()`.
#' @param moments_open_end Open-ended class handling passed to `gs_moments()`.
#' @param n_modes Number of modal classes passed to `gs_modes()` when
#'   `parameters` includes `"modes"`.
#' @param sediment_loss_percent Optional sediment-loss percentages passed to
#'   `gs_quality_flags()` when `parameters` includes `"quality"`.
#' @param sediment_loss_warning_percent Advisory sediment-loss threshold passed
#'   to `gs_quality_flags()`.
#' @param fine_pan_info_percent Advisory fine-pan information threshold passed
#'   to `gs_quality_flags()`.
#' @param fine_pan_warning_percent Advisory fine-pan warning threshold passed
#'   to `gs_quality_flags()`.
#' @param fraction_scheme Fraction scheme passed to `gs_fractions_wide()`.
#' @param fraction_normalize Normalization mode passed to `gs_fractions_wide()`.
#' @param fraction_unresolved Unresolved-threshold behavior passed to
#'   `gs_fractions_wide()`.
#'
#' @return A tibble containing requested grain-size parameters.
#' @export
gs_parameters <- function(x,
                          parameters = c("D10", "D30", "D50", "D60", "D75", "indices"),
                          output = c("wide", "long"),
                          d_values = c(5, 10, 16, 25, 50, 75, 84, 90, 95),
                          interpolation_scale = "phi",
                          extrapolate = "error",
                          d_spread_scale = "um",
                          fine_threshold_um = 62.5,
                          moments_method = "logarithmic_phi",
                          moments_open_end = "error",
                          n_modes = 3,
                          sediment_loss_percent = NULL,
                          sediment_loss_warning_percent = 2,
                          fine_pan_info_percent = 1,
                          fine_pan_warning_percent = 5,
                          fraction_scheme = "wentworth_major",
                          fraction_normalize = "none",
                          fraction_unresolved = "warn_na") {
  validate_gsd_tbl(x)
  output <- match.arg(output)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))
  d_spread_scale <- match.arg(d_spread_scale, c("um", "mm"))
  moments_method <- match.arg(moments_method, c("logarithmic_phi", "arithmetic_um"))
  moments_open_end <- match.arg(moments_open_end, c("error", "extend_phi", "omit"))
  fraction_scheme <- match.arg(
    fraction_scheme,
    c(
      "wentworth_major",
      "gradistat",
      "usda_tt",
      "isss",
      "uk_ssew",
      "hypres",
      "germany_63",
      "australia_20",
      "sweden_60"
    )
  )
  fraction_normalize <- match.arg(fraction_normalize, c("none", "fine_earth"))
  fraction_unresolved <- match.arg(fraction_unresolved, c("warn_na", "error"))

  if (!is.character(parameters) || anyNA(parameters)) {
    stop("`parameters` must be a character vector without missing values.", call. = FALSE)
  }

  supported <- grepl("^D[0-9]+(\\.[0-9]+)?$", parameters) |
    parameters %in% c(
      "d_values", "d_spread", "indices", "engineering",
      "folk_ward", "moments", "modes", "descriptors", "quality", "fractions"
    )
  if (any(!supported)) {
    stop(
      "Unsupported parameters: ",
      paste(parameters[!supported], collapse = ", "),
      ". Supported values are `d_values`, D-value tokens, `d_spread`, `indices`, `folk_ward`, `moments`, `modes`, `descriptors`, `quality`, and `fractions`.",
      call. = FALSE
    )
  }

  if (!is.numeric(d_values) || anyNA(d_values)) {
    stop("`d_values` must be a numeric vector without missing values.", call. = FALSE)
  }

  if (any(d_values < 0 | d_values > 100)) {
    stop("`d_values` must contain values on the 0-100 scale.", call. = FALSE)
  }
  if (!is.numeric(n_modes) || length(n_modes) != 1 || is.na(n_modes) || n_modes < 1) {
    stop("`n_modes` must be a positive whole number.", call. = FALSE)
  }
  n_modes <- as.integer(n_modes)

  parameters[parameters == "engineering"] <- "indices"

  sample_ids <- unique(as.character(x$sample_id))
  wide <- tibble::tibble(sample_id = sample_ids)

  probs <- unique(c(
    parse_d_parameters(parameters),
    if ("d_values" %in% parameters) d_values else numeric()
  ))
  if (length(probs) > 0) {
    percentile_values <- gs_d_values(
      x,
      probs = probs,
      interpolation_scale = interpolation_scale,
      output_unit = "um",
      extrapolate = extrapolate
    )
    percentile_wide <- tibble::tibble(sample_id = sample_ids)
    for (prob in probs) {
      values <- percentile_values$grain_size_um[percentile_values$percentile == prob]
      names(values) <- percentile_values$sample_id[percentile_values$percentile == prob]
      percentile_wide[[paste0("D", prob, "_um")]] <- unname(values[percentile_wide$sample_id])
    }
    wide <- merge(wide, percentile_wide, by = "sample_id", all.x = TRUE, sort = FALSE)
  }

  if ("d_spread" %in% parameters) {
    d_spread <- gs_d_spread(
      x,
      scale = d_spread_scale,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )
    new_cols <- setdiff(names(d_spread), names(wide))
    wide <- merge(
      wide,
      d_spread[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("indices" %in% parameters) {
    indices <- gs_grain_size_indices(
      x,
      fine_threshold_um = fine_threshold_um,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )
    new_cols <- setdiff(names(indices), names(wide))
    wide <- merge(
      wide,
      indices[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("folk_ward" %in% parameters) {
    folkward <- gs_folk_ward(
      x,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate,
      include_descriptions = TRUE
    )
    new_cols <- setdiff(names(folkward), names(wide))
    wide <- merge(
      wide,
      folkward[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("moments" %in% parameters) {
    moments <- moments_for_parameters(
      x,
      moments_method = moments_method,
      moments_open_end = moments_open_end
    )
    new_cols <- setdiff(names(moments), names(wide))
    wide <- merge(
      wide,
      moments[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("descriptors" %in% parameters) {
    descriptor_source <- if ("folk_ward" %in% parameters) {
      wide
    } else {
      gs_folk_ward(
        x,
        interpolation_scale = interpolation_scale,
        extrapolate = extrapolate,
        include_descriptions = FALSE
      )
    }
    descriptors <- gs_describe_parameters(descriptor_source, method = "auto")
    keep <- c(
      "sample_id", "mean_description", "sorting_description",
      "skewness_description", "kurtosis_description",
      "description_method", "description_status"
    )
    new_cols <- setdiff(keep, names(wide))
    wide <- merge(
      wide,
      descriptors[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("modes" %in% parameters) {
    modes <- modes_for_parameters(x, n_modes = n_modes)
    new_cols <- setdiff(names(modes), names(wide))
    wide <- merge(
      wide,
      modes[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("quality" %in% parameters) {
    quality <- quality_for_parameters(
      x,
      sediment_loss_percent = sediment_loss_percent,
      sediment_loss_warning_percent = sediment_loss_warning_percent,
      fine_pan_info_percent = fine_pan_info_percent,
      fine_pan_warning_percent = fine_pan_warning_percent
    )
    new_cols <- setdiff(names(quality), names(wide))
    wide <- merge(
      wide,
      quality[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("fractions" %in% parameters) {
    fractions <- gs_fractions_wide(
      x,
      scheme = fraction_scheme,
      normalize = fraction_normalize,
      interpolation_scale = interpolation_scale,
      unresolved = fraction_unresolved,
      extrapolate = extrapolate
    )
    new_cols <- setdiff(names(fractions), names(wide))
    wide <- merge(
      wide,
      fractions[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  wide <- tibble::as_tibble(wide)
  if (output == "long") {
    return(parameters_to_long(wide))
  }

  wide
}
