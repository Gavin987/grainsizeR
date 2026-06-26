quality_flag_row <- function(sample_id, flag, status, value, threshold, message) {
  tibble::tibble(
    sample_id = as.character(sample_id),
    quality_flag = flag,
    quality_status = status,
    quality_value = as.character(value),
    quality_threshold = as.character(threshold),
    quality_message = message
  )
}

quality_flags_one_sample <- function(sample_data,
                                     sediment_loss_percent,
                                     sediment_loss_warning_percent,
                                     fine_pan_info_percent,
                                     fine_pan_warning_percent) {
  sample_id <- sample_data$sample_id[1]
  fine_tail <- sample_data[sample_data$is_open_lower, , drop = FALSE]
  fine_pan_percent <- if (nrow(fine_tail) == 0) NA_real_ else sum(fine_tail$retained_percent, na.rm = TRUE)
  has_open_fine <- nrow(fine_tail) > 0 && fine_pan_percent > 0

  loss_value <- sediment_loss_percent[[sample_id]]
  loss_row <- if (is.null(loss_value) || is.na(loss_value)) {
    quality_flag_row(
      sample_id,
      "sediment_loss",
      "not_evaluated",
      NA_character_,
      paste0("> ", sediment_loss_warning_percent, "%"),
      "Sediment-loss percentage was not supplied."
    )
  } else if (loss_value > sediment_loss_warning_percent) {
    quality_flag_row(
      sample_id,
      "sediment_loss",
      "warning",
      loss_value,
      paste0("> ", sediment_loss_warning_percent, "%"),
      "Sediment loss exceeds the GRADISTAT-inspired advisory threshold."
    )
  } else {
    quality_flag_row(
      sample_id,
      "sediment_loss",
      "ok",
      loss_value,
      paste0("<= ", sediment_loss_warning_percent, "%"),
      "Supplied sediment-loss percentage is within the advisory threshold."
    )
  }

  open_row <- if (has_open_fine) {
    quality_flag_row(
      sample_id,
      "open_fine_tail",
      "needs_additional_analysis",
      TRUE,
      "reported explicitly",
      "The sample has retained material in an open-ended fine pan fraction."
    )
  } else {
    quality_flag_row(
      sample_id,
      "open_fine_tail",
      "ok",
      FALSE,
      "no retained open fine pan fraction",
      "No retained material was found in the open-ended fine pan fraction."
    )
  }

  pan_status <- if (!has_open_fine) {
    "ok"
  } else if (fine_pan_percent >= fine_pan_warning_percent) {
    "warning"
  } else if (fine_pan_percent >= fine_pan_info_percent) {
    "needs_additional_analysis"
  } else {
    "ok"
  }

  pan_row <- quality_flag_row(
    sample_id,
    "fine_pan_fraction",
    pan_status,
    fine_pan_percent,
    paste0(fine_pan_info_percent, "% info; ", fine_pan_warning_percent, "% warning"),
    if (pan_status == "warning") {
      "The open fine pan fraction is large enough to affect fine-tail interpretation."
    } else if (pan_status == "needs_additional_analysis") {
      "The open fine pan fraction is present and should be considered when interpreting fine-tail statistics."
    } else {
      "The open fine pan fraction is below the advisory thresholds."
    }
  )

  rbind(loss_row, open_row, pan_row)
}

#' Report GRADISTAT-inspired quality flags
#'
#' `gs_quality_flags()` returns lightweight advisory flags for conditions that
#' affect GRADISTAT-style grain-size interpretation. It currently reports
#' sediment-loss status when the user supplies loss percentages, open fine-tail
#' status from `gsd_tbl` class structure, and advisory fine-pan fraction
#' thresholds.
#'
#' The function does not invent mass-loss information. If sediment-loss values
#' are not supplied, the sediment-loss flag is returned as `"not_evaluated"`.
#' Open-tail flags are advisory and do not replace method-specific open-tail
#' handling in D-values, fractions, moments, or other calculations.
#'
#' @param x A valid `gsd_tbl` object.
#' @param sediment_loss_percent Optional sediment-loss percentages. Supply a
#'   named numeric vector keyed by `sample_id`, or an unnamed scalar for a
#'   single-sample object.
#' @param sediment_loss_warning_percent Advisory sediment-loss warning
#'   threshold. The default is 2 percent.
#' @param fine_pan_info_percent Advisory lower threshold for noting a retained
#'   open fine pan fraction.
#' @param fine_pan_warning_percent Advisory warning threshold for a retained
#'   open fine pan fraction.
#'
#' @return A tibble with quality flag rows by sample.
#' @export
gs_quality_flags <- function(x,
                             sediment_loss_percent = NULL,
                             sediment_loss_warning_percent = 2,
                             fine_pan_info_percent = 1,
                             fine_pan_warning_percent = 5) {
  validate_gsd_tbl(x)

  if (!is.numeric(sediment_loss_warning_percent) || length(sediment_loss_warning_percent) != 1) {
    stop("`sediment_loss_warning_percent` must be a single numeric value.", call. = FALSE)
  }
  if (!is.numeric(fine_pan_info_percent) || length(fine_pan_info_percent) != 1) {
    stop("`fine_pan_info_percent` must be a single numeric value.", call. = FALSE)
  }
  if (!is.numeric(fine_pan_warning_percent) || length(fine_pan_warning_percent) != 1) {
    stop("`fine_pan_warning_percent` must be a single numeric value.", call. = FALSE)
  }

  sample_ids <- unique(as.character(x$sample_id))
  loss <- as.list(stats::setNames(rep(NA_real_, length(sample_ids)), sample_ids))
  if (!is.null(sediment_loss_percent)) {
    if (!is.numeric(sediment_loss_percent)) {
      stop("`sediment_loss_percent` must be numeric when supplied.", call. = FALSE)
    }
    if (is.null(names(sediment_loss_percent))) {
      if (length(sample_ids) != 1 || length(sediment_loss_percent) != 1) {
        stop("Unnamed `sediment_loss_percent` is only supported for one-sample input.", call. = FALSE)
      }
      loss[[sample_ids[1]]] <- sediment_loss_percent[1]
    } else {
      for (sample_id in intersect(sample_ids, names(sediment_loss_percent))) {
        loss[[sample_id]] <- sediment_loss_percent[[sample_id]]
      }
    }
  }

  split_data <- split(x, x$sample_id, drop = TRUE)
  rows <- lapply(
    split_data,
    quality_flags_one_sample,
    sediment_loss_percent = loss,
    sediment_loss_warning_percent = sediment_loss_warning_percent,
    fine_pan_info_percent = fine_pan_info_percent,
    fine_pan_warning_percent = fine_pan_warning_percent
  )

  out <- do.call(rbind, unname(rows))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
