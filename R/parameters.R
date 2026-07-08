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
      "D75_minus_D25", "D90_D10_log_ratio", "D75_D25_log_ratio",
      "quartile_deviation_phi"
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
      parameter == "sd_moment_phi" ||
      parameter == "quartile_deviation_phi"
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
  flag_groups <- split(flags, flags$sample_id, drop = TRUE)
  out$quality_overall_status <- vapply(sample_ids, function(sample_id) {
    one <- flag_groups[[sample_id]]
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

.merge_new_parameter_columns <- function(wide, addition, columns = names(addition)) {
  columns <- intersect(columns, names(addition))
  new_cols <- setdiff(columns, names(wide))
  if (length(new_cols) == 0) {
    return(wide)
  }

  merge(
    wide,
    addition[c("sample_id", new_cols)],
    by = "sample_id",
    all.x = TRUE,
    sort = FALSE
  )
}

# Internal gs_parameters() adapters that reuse one cumulative curve per call.
# Public wrappers keep computing their own curves when called directly.
.parameters_split_curve <- function(x) {
  curve <- gs_cumulative(x)
  split(curve, curve$sample_id, drop = TRUE)
}

.parameters_d_values_from_curve <- function(split_curve, probs, interpolation_scale, extrapolate) {
  percentiles <- lapply(
    split_curve,
    percentile_one_sample,
    probs = probs,
    scale = interpolation_scale,
    extrapolate = extrapolate
  )

  out <- do.call(rbind, unname(percentiles))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

.parameters_percent_finer_from_curve <- function(split_curve, sizes, size_unit, interpolation_scale, extrapolate) {
  threshold_um <- thresholds_to_um(sizes, size_unit)
  rows <- lapply(
    split_curve,
    percent_finer_one_sample,
    threshold_um = threshold_um,
    scale = interpolation_scale,
    extrapolate = extrapolate
  )

  out <- do.call(rbind, unname(rows))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

.parameters_percent_finer_lookup_from_curve <- function(x,
                                                        split_curve,
                                                        thresholds_mm,
                                                        interpolation_scale,
                                                        extrapolate,
                                                        unresolved) {
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
    curve <- split_curve[[sample_id]]
    finite_mm <- curve$boundary_mm
    min_mm <- min(finite_mm)
    max_mm <- max(finite_mm)

    equivalent_boundary <- vapply(
      thresholds_mm,
      function(t) nominally_equivalent_boundary_mm(t, finite_mm),
      numeric(1)
    )
    has_equivalent <- !is.na(equivalent_boundary)

    in_range <- (thresholds_mm >= min_mm & thresholds_mm <= max_mm) | has_equivalent
    resolved_lookup <- NULL
    if (any(in_range)) {
      resolved_lookup <- tryCatch(
        percent_finer_one_sample(
          curve,
          threshold_um = mm_to_um(thresholds_mm[in_range]),
          scale = interpolation_scale,
          extrapolate = extrapolate
        ),
        error = function(err) NULL
      )
    }

    for (i in seq_along(thresholds_mm)) {
      threshold <- thresholds_mm[i]
      threshold_has_equivalent <- has_equivalent[i]

      if (threshold < min_mm && !threshold_has_equivalent) {
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
          extrapolated_lookup <- tryCatch(
            percent_finer_one_sample(
              curve,
              threshold_um = mm_to_um(threshold),
              scale = interpolation_scale,
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

.parameters_grain_size_indices_from_curve <- function(x,
                                                      split_curve,
                                                      fine_threshold_um,
                                                      interpolation_scale,
                                                      extrapolate) {
  percentiles <- .parameters_d_values_from_curve(
    split_curve,
    probs = c(10, 25, 30, 50, 60, 75),
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate
  )
  fine_content <- .parameters_percent_finer_from_curve(
    split_curve,
    sizes = fine_threshold_um,
    size_unit = "um",
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate
  )

  sample_ids <- unique(percentiles$sample_id)
  percentile_groups <- split(percentiles, percentiles$sample_id, drop = TRUE)
  fine_content_groups <- split(fine_content, fine_content$sample_id, drop = TRUE)
  rows <- lapply(
    sample_ids,
    engineering_one_sample,
    percentiles = percentile_groups,
    fine_content = fine_content_groups,
    interpolation_scale = interpolation_scale,
    fine_threshold_um = fine_threshold_um
  )

  out <- do.call(rbind, unname(rows))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

.parameters_folk_ward_from_curve <- function(split_curve,
                                             interpolation_scale,
                                             extrapolate,
                                             include_descriptions) {
  percentiles <- .parameters_d_values_from_curve(
    split_curve,
    probs = c(5, 16, 25, 50, 75, 84, 95),
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate
  )

  sample_ids <- unique(percentiles$sample_id)
  percentile_groups <- split(percentiles, percentiles$sample_id, drop = TRUE)
  rows <- lapply(
    sample_ids,
    folkward_one_sample,
    percentiles = percentile_groups,
    interpolation_scale = interpolation_scale,
    include_descriptions = include_descriptions
  )

  out <- do.call(rbind, unname(rows))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

.parameters_fractions_wide_from_curve <- function(x,
                                                  split_curve,
                                                  scheme,
                                                  normalize,
                                                  interpolation_scale,
                                                  unresolved,
                                                  extrapolate) {
  components <- scheme_components(scheme)
  thresholds <- required_fraction_thresholds(components)
  lookup <- .parameters_percent_finer_lookup_from_curve(
    x,
    split_curve = split_curve,
    thresholds_mm = thresholds,
    interpolation_scale = interpolation_scale,
    extrapolate = extrapolate,
    unresolved = unresolved
  )

  sample_ids <- unique(as.character(x$sample_id))
  lookup_groups <- lookup_by_sample(lookup)
  fractions <- lapply(
    sample_ids,
    fractions_one_sample,
    components = components,
    lookup = lookup_groups,
    scheme = scheme,
    normalize = normalize,
    interpolation_scale = interpolation_scale
  )
  fractions <- do.call(rbind, fractions)
  rownames(fractions) <- NULL

  components <- unique(fractions$component)
  out <- tibble::tibble(sample_id = unique(fractions$sample_id))
  for (component in components) {
    values <- fractions$percent[fractions$component == component]
    names(values) <- fractions$sample_id[fractions$component == component]
    out[[paste0(component, "_percent")]] <- unname(values[out$sample_id])
  }

  out
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
#' Any D-value tokens are ultimately computed by `gs_d_values()`, including
#' its deterministic tie-breaking rule for percentiles that fall on a
#' plateau caused by consecutive zero-retained classes (see `gs_d_values()`
#' for details).
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
  fraction_scheme <- .validate_fraction_scheme(fraction_scheme, arg = "fraction_scheme")
  fraction_normalize <- match.arg(fraction_normalize, c("none", "fine_earth"))
  fraction_unresolved <- match.arg(fraction_unresolved, c("warn_na", "error"))
  .validate_fraction_normalize_scheme(fraction_scheme, fraction_normalize)

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
  split_curve <- NULL
  shared_curve <- function() {
    if (is.null(split_curve)) {
      split_curve <<- .parameters_split_curve(x)
    }
    split_curve
  }

  probs <- unique(c(
    parse_d_parameters(parameters),
    if ("d_values" %in% parameters) d_values else numeric()
  ))
  if (length(probs) > 0) {
    percentile_values <- .parameters_d_values_from_curve(
      shared_curve(),
      probs = probs,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )
    percentile_wide <- tibble::tibble(sample_id = sample_ids)
    for (prob in probs) {
      values <- percentile_values$grain_size_um[percentile_values$percentile == prob]
      names(values) <- percentile_values$sample_id[percentile_values$percentile == prob]
      percentile_wide[[paste0("D", prob, "_um")]] <- unname(values[percentile_wide$sample_id])
    }
    wide <- .merge_new_parameter_columns(wide, percentile_wide)
  }

  if ("d_spread" %in% parameters) {
    percentiles <- .parameters_d_values_from_curve(
      shared_curve(),
      probs = c(10, 25, 50, 75, 90),
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )
    d_spread <- d_spread_values(percentiles, scale = d_spread_scale)
    wide <- .merge_new_parameter_columns(wide, d_spread)
  }

  if ("indices" %in% parameters) {
    indices <- .parameters_grain_size_indices_from_curve(
      x,
      split_curve = shared_curve(),
      fine_threshold_um = fine_threshold_um,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )
    wide <- .merge_new_parameter_columns(wide, indices)
  }

  if ("folk_ward" %in% parameters) {
    folkward <- .parameters_folk_ward_from_curve(
      shared_curve(),
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate,
      include_descriptions = TRUE
    )
    wide <- .merge_new_parameter_columns(wide, folkward)
  }

  if ("moments" %in% parameters) {
    moments <- moments_for_parameters(
      x,
      moments_method = moments_method,
      moments_open_end = moments_open_end
    )
    wide <- .merge_new_parameter_columns(wide, moments)
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
    wide <- .merge_new_parameter_columns(wide, descriptors, columns = keep)
  }

  if ("modes" %in% parameters) {
    modes <- modes_for_parameters(x, n_modes = n_modes)
    wide <- .merge_new_parameter_columns(wide, modes)
  }

  if ("quality" %in% parameters) {
    quality <- quality_for_parameters(
      x,
      sediment_loss_percent = sediment_loss_percent,
      sediment_loss_warning_percent = sediment_loss_warning_percent,
      fine_pan_info_percent = fine_pan_info_percent,
      fine_pan_warning_percent = fine_pan_warning_percent
    )
    wide <- .merge_new_parameter_columns(wide, quality)
  }

  if ("fractions" %in% parameters) {
    fractions <- .parameters_fractions_wide_from_curve(
      x,
      split_curve = shared_curve(),
      scheme = fraction_scheme,
      normalize = fraction_normalize,
      interpolation_scale = interpolation_scale,
      unresolved = fraction_unresolved,
      extrapolate = extrapolate
    )
    wide <- .merge_new_parameter_columns(wide, fractions)
  }

  wide <- tibble::as_tibble(wide)
  if (output == "long") {
    return(parameters_to_long(wide))
  }

  wide
}
