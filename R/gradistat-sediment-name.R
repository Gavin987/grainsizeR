.gradistat_gravel_subclass_columns <- c(
  "very_coarse_gravel", "coarse_gravel", "medium_gravel",
  "fine_gravel", "very_fine_gravel"
)

.gradistat_sand_subclass_columns <- c(
  "very_coarse_sand", "coarse_sand", "medium_sand",
  "fine_sand", "very_fine_sand"
)

.gradistat_silt_subclass_columns <- c(
  "very_coarse_silt", "coarse_silt", "medium_silt",
  "fine_silt", "very_fine_silt"
)

.gradistat_subclass_labels <- c(
  very_coarse_gravel = "very coarse gravel",
  coarse_gravel = "coarse gravel",
  medium_gravel = "medium gravel",
  fine_gravel = "fine gravel",
  very_fine_gravel = "very fine gravel",
  very_coarse_sand = "very coarse sand",
  coarse_sand = "coarse sand",
  medium_sand = "medium sand",
  fine_sand = "fine sand",
  very_fine_sand = "very fine sand",
  very_coarse_silt = "very coarse silt",
  coarse_silt = "coarse silt",
  medium_silt = "medium silt",
  fine_silt = "fine silt",
  very_fine_silt = "very fine silt"
)

.dominant_gradistat_subclass <- function(x, columns) {
  present <- intersect(columns, names(x))
  if (length(present) == 0) {
    return(rep(NA_character_, nrow(x)))
  }
  for (column in present) {
    invalid <- !is.na(x[[column]]) & (!is.finite(x[[column]]) | x[[column]] < 0 | x[[column]] > 100)
    if (!is.numeric(x[[column]]) || any(invalid)) {
      stop("GRADISTAT subclass percentages must be numeric, finite, and between 0 and 100.", call. = FALSE)
    }
  }

  values <- as.data.frame(x[present])
  out <- character(nrow(x))
  for (i in seq_len(nrow(x))) {
    row <- unlist(values[i, ], use.names = TRUE)
    if (all(is.na(row)) || all(row == 0, na.rm = TRUE)) {
      out[i] <- NA_character_
    } else {
      row[is.na(row)] <- -Inf
      out[i] <- unname(.gradistat_subclass_labels[names(row)[which.max(row)]])
    }
  }
  out
}

.gradistat_texture_basis <- function(x) {
  if ("ternary_basis" %in% names(x)) {
    return(as.character(x$ternary_basis))
  }
  rep(NA_character_, nrow(x))
}

.gradistat_class_from_existing <- function(x, basis) {
  if (!all(c("texture_class_id", "texture_class") %in% names(x))) {
    return(list(class_id = rep(NA_character_, nrow(x)), class_name = rep(NA_character_, nrow(x))))
  }
  row_basis <- .gradistat_texture_basis(x)
  use <- is.na(row_basis) | row_basis == basis
  list(
    class_id = ifelse(use, as.character(x$texture_class_id), NA_character_),
    class_name = ifelse(use, as.character(x$texture_class), NA_character_)
  )
}

.gradistat_class_from_components <- function(x, basis) {
  required <- if (basis == "gravel_sand_mud") c("gravel", "sand", "mud") else c("sand", "silt", "clay")
  if (!all(required %in% names(x))) {
    return(list(class_id = rep(NA_character_, nrow(x)), class_name = rep(NA_character_, nrow(x))))
  }
  complete <- stats::complete.cases(x[required])
  class_id <- rep(NA_character_, nrow(x))
  class_name <- rep(NA_character_, nrow(x))
  if (!any(complete)) {
    return(list(class_id = class_id, class_name = class_name))
  }
  classified <- .classify_gradistat_texture_rules(x[complete, , drop = FALSE], basis = basis)
  class_id[complete] <- classified$texture_class_id
  class_name[complete] <- classified$texture_class
  list(
    class_id = class_id,
    class_name = class_name
  )
}

.fill_missing_gradistat_class <- function(existing, computed) {
  missing <- is.na(existing$class_id)
  existing$class_id[missing] <- computed$class_id[missing]
  existing$class_name[missing] <- computed$class_name[missing]
  existing
}

.compose_gradistat_name <- function(class_name, gravel_class, sand_class, silt_class) {
  if (is.na(class_name)) {
    return(NA_character_)
  }
  words <- strsplit(class_name, " ", fixed = TRUE)[[1]]
  last <- words[length(words)]
  replacement <- switch(
    last,
    gravel = gravel_class,
    sand = sand_class,
    silt = silt_class,
    NA_character_
  )
  if (last == "mud" && !is.na(silt_class)) {
    replacement <- silt_class
  }
  if (is.na(replacement)) {
    return(class_name)
  }
  words[length(words)] <- replacement
  paste(words, collapse = " ")
}

#' Compose GRADISTAT-style sediment names
#'
#' `gs_gradistat_sediment_name()` appends GRADISTAT-style sediment-name fields
#' to a data frame. It is intended for data already classified with
#' `classify_texture(..., scheme = "gradistat", method = "rules")`, or for data
#' frames containing the GRADISTAT major components needed to compute the
#' textural group. `TEXTURAL GROUP` and `SEDIMENT NAME` are distinct outputs:
#' the textural group is the gravel-sand-mud or no-gravel sand-silt-clay class,
#' while the sediment name may add dominant size-subclass wording when those
#' subclass percentages are supplied.
#'
#' The function re-expresses decision-table behavior recorded from the
#' user-provided GRADISTAT v8 workbook and Blott and Pye (2001). It does not
#' copy VBA source code. GRADISTAT ternary plotting is handled separately and
#' is not implemented by this function.
#'
#' @param x A data frame. It may be output from `classify_texture()` for
#'   `scheme = "gradistat"`, or it may contain `gravel`, `sand`, and `mud`
#'   columns, `sand`, `silt`, and `clay` columns, or both.
#' @param basis Preferred classification basis. `"auto"` uses an existing
#'   `ternary_basis` column when present, otherwise it prefers
#'   `"gravel_sand_mud"` when `gravel`, `sand`, and `mud` are available and
#'   `"sand_silt_clay_no_gravel"` when only `sand`, `silt`, and `clay` are
#'   available.
#'
#' @return A tibble containing the input rows with `textural_group_class_id`,
#'   `textural_group`, `mini_texture_class_id`, `mini_texture_class`,
#'   `dominant_gravel_class`, `dominant_sand_class`, `dominant_silt_class`,
#'   `sediment_name`, `sediment_name_status`, `sediment_name_method`, and
#'   `notes` appended or updated.
#' @export
#'
#' @examples
#' classified <- classify_texture(
#'   data.frame(
#'     sample_id = "A",
#'     gravel = 0,
#'     sand = 95,
#'     mud = 5,
#'     fine_sand = 70,
#'     medium_sand = 25
#'   ),
#'   scheme = "gradistat",
#'   method = "rules",
#'   basis = "gravel_sand_mud"
#' )
#'
#' gs_gradistat_sediment_name(classified)
gs_gradistat_sediment_name <- function(x,
                                       basis = c("auto", "gravel_sand_mud", "sand_silt_clay_no_gravel")) {
  basis <- match.arg(basis)
  if (!is.data.frame(x)) {
    stop("`x` must be a data frame.", call. = FALSE)
  }
  out <- tibble::as_tibble(x)

  if (basis == "auto") {
    basis_vector <- .gradistat_texture_basis(out)
    if (all(is.na(basis_vector))) {
      if (all(c("gravel", "sand", "mud") %in% names(out))) {
        basis_vector <- rep("gravel_sand_mud", nrow(out))
      } else if (all(c("sand", "silt", "clay") %in% names(out))) {
        basis_vector <- rep("sand_silt_clay_no_gravel", nrow(out))
      } else {
        basis_vector <- rep(NA_character_, nrow(out))
      }
    }
  } else {
    basis_vector <- rep(basis, nrow(out))
  }

  textural_group <- .gradistat_class_from_existing(out, "gravel_sand_mud")
  textural_group <- .fill_missing_gradistat_class(
    textural_group,
    .gradistat_class_from_components(out, "gravel_sand_mud")
  )
  mini_texture <- .gradistat_class_from_existing(out, "sand_silt_clay_no_gravel")
  mini_texture <- .fill_missing_gradistat_class(
    mini_texture,
    .gradistat_class_from_components(out, "sand_silt_clay_no_gravel")
  )

  out$textural_group_class_id <- textural_group$class_id
  out$textural_group <- textural_group$class_name
  out$mini_texture_class_id <- mini_texture$class_id
  out$mini_texture_class <- mini_texture$class_name
  out$dominant_gravel_class <- .dominant_gradistat_subclass(out, .gradistat_gravel_subclass_columns)
  out$dominant_sand_class <- .dominant_gradistat_subclass(out, .gradistat_sand_subclass_columns)
  out$dominant_silt_class <- .dominant_gradistat_subclass(out, .gradistat_silt_subclass_columns)

  selected_class <- ifelse(
    basis_vector == "sand_silt_clay_no_gravel",
    out$mini_texture_class,
    out$textural_group
  )
  selected_class_id <- ifelse(
    basis_vector == "sand_silt_clay_no_gravel",
    out$mini_texture_class_id,
    out$textural_group_class_id
  )

  out$sediment_name <- vapply(
    seq_len(nrow(out)),
    function(i) {
      .compose_gradistat_name(
        selected_class[i],
        out$dominant_gravel_class[i],
        out$dominant_sand_class[i],
        out$dominant_silt_class[i]
      )
    },
    character(1)
  )

  has_any_subclass <- !is.na(out$dominant_gravel_class) |
    !is.na(out$dominant_sand_class) |
    !is.na(out$dominant_silt_class)
  out$sediment_name_status <- ifelse(
    is.na(selected_class_id),
    "invalid",
    ifelse(has_any_subclass, "resolved", "missing_subclass_data")
  )
  out$sediment_name_method <- "gradistat_sediment_name_rules"
  sediment_notes <- ifelse(
    out$sediment_name_status == "missing_subclass_data",
    "Textural group was returned without dominant size-subclass modifiers because subclass columns were not supplied.",
    ifelse(
      out$sediment_name_status == "invalid",
      "GRADISTAT sediment name could not be resolved from the supplied classification or component columns.",
      NA_character_
    )
  )

  if ("notes" %in% names(x)) {
    old_notes <- as.character(x$notes)
    out$notes <- ifelse(
      is.na(old_notes) | old_notes == "",
      sediment_notes,
      ifelse(is.na(sediment_notes), old_notes, paste(old_notes, sediment_notes, sep = " "))
    )
  } else {
    out$notes <- sediment_notes
  }

  tibble::as_tibble(out)
}
