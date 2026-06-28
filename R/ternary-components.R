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

.match_component_columns <- function(x, required) {
  canonical_names <- .canonical_component_name(names(x))
  stats::setNames(vapply(required, function(component) {
    hits <- which(canonical_names == component)
    if (length(hits) == 0) {
      NA_character_
    } else {
      names(x)[hits[1]]
    }
  }, character(1)), required)
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
  }

  if (is.null(out)) {
    direct_cols <- .match_component_columns(x, required)
    if (all(!is.na(direct_cols))) {
      out <- tibble::as_tibble(x)
      for (component in required) {
        if (!identical(direct_cols[[component]], component)) {
          out[[component]] <- out[[direct_cols[[component]]]]
        }
      }
    }
  }

  if (is.null(out)) {
    percent_cols <- paste0(required, "_percent")
    if (all(percent_cols %in% names(x))) {
      if ("sample_id" %in% names(x)) {
        out <- tibble::tibble(sample_id = x$sample_id)
      } else {
        out <- tibble::tibble(.rows = nrow(x))
      }
      for (component in required) {
        out[[component]] <- x[[paste0(component, "_percent")]]
      }
    }
  }

  if (is.null(out)) {
    stop(
      "Ternary plotting requires columns: ",
      paste(required, collapse = ", "),
      call. = FALSE
    )
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
