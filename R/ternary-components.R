.canonical_component_name <- function(x) {
  tolower(as.character(x))
}

.ternary_component_set_components <- function(component_set) {
  switch(
    component_set,
    gravel_sand_mud = c("gravel", "sand", "mud"),
    sand_silt_clay = c("sand", "silt", "clay"),
    sand_silt_clay_no_gravel = c("sand", "silt", "clay"),
    stop("Unknown ternary component set: ", component_set, call. = FALSE)
  )
}

.match_component_columns <- function(x, required, suffix = "") {
  canonical_names <- .canonical_component_name(names(x))
  stats::setNames(vapply(required, function(component) {
    hits <- which(canonical_names == paste0(component, suffix))
    if (length(hits) == 0) {
      NA_character_
    } else {
      names(x)[hits[1]]
    }
  }, character(1)), required)
}

.ternary_component_error <- function(component_set, required) {
  if (identical(component_set, "sand_silt_clay") || identical(component_set, "sand_silt_clay_no_gravel")) {
    return(paste0(
      "Ternary components must include columns `sand`, `silt`, and `clay`, ",
      "or official fraction columns `sand_percent`, `silt_percent`, and `clay_percent`."
    ))
  }
  if (identical(component_set, "gravel_sand_mud")) {
    return(paste0(
      "GRADISTAT ternary components must include columns `gravel`, `sand`, and `mud`; ",
      "official fraction columns `gravel_percent`, `sand_percent`, and `mud_percent`; ",
      "or official GRADISTAT fraction columns `gravel_percent`, `sand_percent`, ",
      "`silt_percent`, and `clay_percent`, where `silt_percent + clay_percent` ",
      "approximates mud (GRADISTAT's 63 um sand/silt boundary differs slightly from ",
      "the exact 62.5 um Wentworth sand/mud boundary used by `gravel_sand_mud`). ",
      "You can also use `gs_fractions_wide(x, scheme = \"gravel_sand_mud\")`."
    ))
  }
  paste("Ternary plotting requires columns:", paste(required, collapse = ", "))
}

.copy_component_columns <- function(x, component_cols, required) {
  out <- tibble::as_tibble(x)
  for (component in required) {
    if (!identical(component_cols[[component]], component)) {
      out[[component]] <- out[[component_cols[[component]]]]
    }
  }
  out
}

.copy_percent_component_columns <- function(x, percent_cols, required) {
  keep_cols <- setdiff(names(x), unname(percent_cols))
  if (length(keep_cols) > 0) {
    out <- tibble::as_tibble(x[keep_cols])
  } else {
    out <- tibble::tibble(.rows = nrow(x))
  }
  for (component in required) {
    out[[component]] <- x[[percent_cols[[component]]]]
  }
  out
}

.aggregate_gradistat_mud_components <- function(x) {
  base <- c("gravel", "sand", "silt", "clay")

  direct_cols <- .match_component_columns(x, base)
  if (all(!is.na(direct_cols))) {
    out <- .copy_component_columns(x, direct_cols, base)
    out$mud <- out$silt + out$clay
    return(out)
  }

  percent_cols <- .match_component_columns(x, base, suffix = "_percent")
  if (all(!is.na(percent_cols))) {
    out <- .copy_percent_component_columns(x, percent_cols, base)
    out$mud <- out$silt + out$clay
    return(out[setdiff(names(out), c("silt", "clay"))])
  }

  NULL
}

.canonical_ternary_component_table <- function(x,
                                               component_set,
                                               point_id = NULL,
                                               texture_system = NULL) {
  required <- .ternary_component_set_components(component_set)

  if (is_gsd_tbl(x)) {
    if (identical(texture_system, "gradistat")) {
      stop(
        "`plot_texture_ternary()` expects summarized ternary components. ",
        "Run `gs_fractions(x, scheme = \"gravel_sand_mud\")` before plotting GRADISTAT ternary diagrams.",
        call. = FALSE
      )
    }
    stop("`x` must contain summarized ternary component percentages.", call. = FALSE)
  }

  if (!is.data.frame(x)) {
    stop("`x` must be a data frame with summarized ternary component percentages.", call. = FALSE)
  }

  out <- NULL
  canonical_names <- .canonical_component_name(names(x))
  if (all(c("sample_id", "component", "percent") %in% canonical_names)) {
    sample_id_col <- names(x)[canonical_names == "sample_id"][1]
    component_col <- names(x)[canonical_names == "component"][1]
    percent_col <- names(x)[canonical_names == "percent"][1]
    long <- tibble::as_tibble(x)
    long$.component_name <- .canonical_component_name(long[[component_col]])
    long <- long[long$.component_name %in% required, , drop = FALSE]

    keys <- paste(long[[sample_id_col]], long$.component_name, sep = "\r")
    if (any(duplicated(keys))) {
      stop("Official long fraction output must contain one row per sample and ternary component.", call. = FALSE)
    }

    sample_ids <- unique(as.character(long[[sample_id_col]]))
    out <- tibble::tibble(sample_id = sample_ids)
    for (component in required) {
      values <- long[[percent_col]][long$.component_name == component]
      names(values) <- as.character(long[[sample_id_col]][long$.component_name == component])
      out[[component]] <- unname(values[out$sample_id])
    }
    extra_cols <- setdiff(names(long), c(sample_id_col, component_col, percent_col, ".component_name"))
    if (length(extra_cols) > 0) {
      long_groups <- split(long, as.character(long[[sample_id_col]]), drop = TRUE)
      for (column in extra_cols) {
        values <- vapply(sample_ids, function(sample_id) {
          sample_values <- unique(long_groups[[sample_id]][[column]])
          sample_values <- sample_values[!is.na(sample_values)]
          if (length(sample_values) == 1) {
            as.character(sample_values)
          } else {
            NA_character_
          }
        }, character(1))
        if (!all(is.na(values)) && !column %in% names(out)) {
          out[[column]] <- values
        }
      }
    }
  }

  if (is.null(out)) {
    direct_cols <- .match_component_columns(x, required)
    if (all(!is.na(direct_cols))) {
      out <- .copy_component_columns(x, direct_cols, required)
    }
  }

  if (is.null(out)) {
    percent_cols <- .match_component_columns(x, required, suffix = "_percent")
    if (all(!is.na(percent_cols))) {
      out <- .copy_percent_component_columns(x, percent_cols, required)
    }
  }

  if (is.null(out) && identical(component_set, "gravel_sand_mud")) {
    out <- .aggregate_gradistat_mud_components(x)
  }

  if (is.null(out)) {
    stop(.ternary_component_error(component_set, required), call. = FALSE)
  }

  missing_components <- setdiff(required, names(out))
  if (length(missing_components) > 0) {
    stop(.ternary_component_error(component_set, required), call. = FALSE)
  }

  if (!is.null(point_id)) {
    if (!point_id %in% names(out) && point_id %in% names(x)) {
      out[[point_id]] <- x[[point_id]]
    }
    if (!point_id %in% names(out)) {
      stop("`point_id` must name a column in `x`.", call. = FALSE)
    }
  }

  for (component in required) {
    if (!is.numeric(out[[component]])) {
      stop("Ternary component percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
    }
  }

  out
}
