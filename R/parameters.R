parse_d_parameters <- function(parameters) {
  d_tokens <- grep("^D[0-9]+(\\.[0-9]+)?$", parameters, value = TRUE)
  as.numeric(sub("^D", "", d_tokens))
}

parameter_method <- function(parameter) {
  if (grepl("^D[0-9]+(\\.[0-9]+)?_um$", parameter)) {
    "percentile"
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
    "engineering"
  }
}

parameter_unit <- function(parameter) {
  if (
    grepl("^D[0-9]+(\\.[0-9]+)?_um$", parameter) ||
      parameter == "mean_fw_um" ||
      parameter == "fine_threshold_um"
  ) {
    "um"
  } else if (grepl("^D[0-9]+(\\.[0-9]+)?_phi$", parameter) || grepl("_fw_phi$", parameter)) {
    "phi"
  } else if (parameter == "fine_content_percent" || parameter == "fine_equivalent") {
    "percent"
  } else if (parameter == "interpolation_scale" || parameter == "any_extrapolated") {
    NA_character_
  } else {
    "unitless"
  }
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
#' D-value percentiles, the engineering indices returned by `gs_engineering()`,
#' and Folk and Ward graphical statistics returned by `gs_folkward()`.
#'
#' @param x A valid `gsd_tbl` object.
#' @param parameters Character vector of parameters. Supported values are
#'   D-value tokens such as `"D10"`, `"D30"`, and `"D90"`, plus the aliases
#'   `"engineering"` and `"folk_ward"`.
#' @param output Output shape. `"wide"` returns one row per sample, while
#'   `"long"` returns parameter-value rows.
#' @param interpolation_scale Interpolation scale passed to lower-level
#'   calculations.
#' @param extrapolate Extrapolation behavior passed to lower-level
#'   calculations.
#' @param fine_threshold_um Fine-content threshold in micrometers for
#'   engineering summaries.
#'
#' @return A tibble containing requested grain-size parameters.
#' @export
gs_parameters <- function(x,
                          parameters = c("D10", "D30", "D50", "D60", "D75", "engineering"),
                          output = c("wide", "long"),
                          interpolation_scale = "phi",
                          extrapolate = "error",
                          fine_threshold_um = 62.5) {
  validate_gsd_tbl(x)
  output <- match.arg(output)
  interpolation_scale <- match.arg(interpolation_scale, c("phi", "log_um", "linear_um"))
  extrapolate <- match.arg(extrapolate, c("error", "warn_linear"))

  if (!is.character(parameters) || anyNA(parameters)) {
    stop("`parameters` must be a character vector without missing values.", call. = FALSE)
  }

  supported <- grepl("^D[0-9]+(\\.[0-9]+)?$", parameters) |
    parameters %in% c("engineering", "folk_ward")
  if (any(!supported)) {
    stop(
      "Unsupported parameters: ",
      paste(parameters[!supported], collapse = ", "),
      ". Supported values are D-value tokens, `engineering`, and `folk_ward`.",
      call. = FALSE
    )
  }

  sample_ids <- unique(as.character(x$sample_id))
  wide <- tibble::tibble(sample_id = sample_ids)

  probs <- unique(parse_d_parameters(parameters))
  if (length(probs) > 0) {
    percentile_values <- gs_percentile(
      x,
      probs = probs,
      scale = interpolation_scale,
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

  if ("engineering" %in% parameters) {
    engineering <- gs_engineering(
      x,
      fine_threshold_um = fine_threshold_um,
      interpolation_scale = interpolation_scale,
      extrapolate = extrapolate
    )
    new_cols <- setdiff(names(engineering), names(wide))
    wide <- merge(
      wide,
      engineering[c("sample_id", new_cols)],
      by = "sample_id",
      all.x = TRUE,
      sort = FALSE
    )
  }

  if ("folk_ward" %in% parameters) {
    folkward <- gs_folkward(
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

  wide <- tibble::as_tibble(wide)
  if (output == "long") {
    return(parameters_to_long(wide))
  }

  wide
}
