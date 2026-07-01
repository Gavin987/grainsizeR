mode_class_label <- function(row) {
  if (isTRUE(row$is_open_upper)) {
    paste0("> ", format(um_to_mm(row$size_lower_um), trim = TRUE), " mm")
  } else if (isTRUE(row$is_open_lower)) {
    paste0("< ", format(um_to_mm(row$size_upper_um), trim = TRUE), " mm")
  } else {
    paste0(
      format(um_to_mm(row$size_lower_um), trim = TRUE),
      "-",
      format(um_to_mm(row$size_upper_um), trim = TRUE),
      " mm"
    )
  }
}

sample_modality_value <- function(sample_data) {
  positive <- sample_data$retained_percent[sample_data$retained_percent > 0]
  if (length(positive) == 0) {
    return("unresolved")
  }

  ordered <- sort(positive, decreasing = TRUE)
  if (length(ordered) > 1 && isTRUE(all.equal(ordered[1], ordered[2]))) {
    return("flat_or_tied")
  }

  local_peak <- rep(FALSE, nrow(sample_data))
  for (i in seq_len(nrow(sample_data))) {
    left <- if (i == 1) -Inf else sample_data$retained_percent[i - 1]
    right <- if (i == nrow(sample_data)) -Inf else sample_data$retained_percent[i + 1]
    local_peak[i] <- sample_data$retained_percent[i] > left &&
      sample_data$retained_percent[i] > right &&
      sample_data$retained_percent[i] > 0
  }
  n_peak <- sum(local_peak)

  if (n_peak <= 1) {
    "unimodal"
  } else if (n_peak == 2) {
    "bimodal"
  } else {
    "trimodal_or_more"
  }
}

mode_status_value <- function(row, tied) {
  if (isTRUE(row$is_open_lower) || isTRUE(row$is_open_upper)) {
    return("open_interval")
  }
  if (isTRUE(tied)) {
    return("tied")
  }
  "resolved"
}

modes_one_sample <- function(sample_data, n_modes) {
  sample_data <- sample_data[order(sample_data$bin_id), ]
  modality <- sample_modality_value(sample_data)
  if (all(sample_data$retained_percent <= 0)) {
    return(tibble::tibble(
      sample_id = sample_data$sample_id[1],
      sample_modality = "unresolved",
      mode_rank = seq_len(n_modes),
      mode_size_mm = NA_real_,
      mode_size_um = NA_real_,
      mode_phi = NA_real_,
      mode_class_lower_mm = NA_real_,
      mode_class_upper_mm = NA_real_,
      mode_percent = NA_real_,
      mode_class_label = NA_character_,
      is_open_interval = NA,
      mode_status = "unresolved"
    ))
  }

  ordered <- sample_data[order(-sample_data$retained_percent, sample_data$bin_id), ]
  selected <- ordered[seq_len(min(n_modes, nrow(ordered))), ]
  tied_values <- duplicated(selected$retained_percent) |
    duplicated(selected$retained_percent, fromLast = TRUE) |
    selected$retained_percent %in% ordered$retained_percent[duplicated(ordered$retained_percent)]

  rows <- lapply(seq_len(n_modes), function(i) {
    if (i > nrow(selected)) {
      return(tibble::tibble(
        sample_id = sample_data$sample_id[1],
        sample_modality = modality,
        mode_rank = i,
        mode_size_mm = NA_real_,
        mode_size_um = NA_real_,
        mode_phi = NA_real_,
        mode_class_lower_mm = NA_real_,
        mode_class_upper_mm = NA_real_,
        mode_percent = NA_real_,
        mode_class_label = NA_character_,
        is_open_interval = NA,
        mode_status = "unresolved"
      ))
    }

    row <- selected[i, ]
    is_open <- row$is_open_lower | row$is_open_upper
    tibble::tibble(
      sample_id = row$sample_id,
      sample_modality = modality,
      mode_rank = i,
      mode_size_mm = if (is_open) NA_real_ else um_to_mm(row$size_mid_um),
      mode_size_um = if (is_open) NA_real_ else row$size_mid_um,
      mode_phi = if (is_open) NA_real_ else row$size_mid_phi,
      mode_class_lower_mm = if (is.na(row$size_lower_um)) NA_real_ else um_to_mm(row$size_lower_um),
      mode_class_upper_mm = if (is.na(row$size_upper_um)) NA_real_ else um_to_mm(row$size_upper_um),
      mode_percent = row$retained_percent,
      mode_class_label = mode_class_label(row),
      is_open_interval = is_open,
      mode_status = mode_status_value(row, tied_values[i])
    )
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

#' Identify modal grain-size classes
#'
#' `gs_modes()` reports the largest retained grain-size classes in each sample.
#' The output is intended for GRADISTAT-style summaries that list primary,
#' secondary, and tertiary modes. Modes are ranked by retained class percentage,
#' with deterministic tie ordering by the original coarse-to-fine class order.
#'
#' The reported mode is a modal class midpoint, not a true continuous density
#' mode. Open-ended terminal classes do not have reliable midpoints; if an
#' open-ended class is selected, midpoint fields are `NA` and `mode_status` is
#' `"open_interval"`. Tied retained percentages are marked with
#' `mode_status = "tied"`. The `sample_modality` column is an operational
#' descriptor based on retained class frequencies, not a formal mixture model.
#'
#' @param x A valid `gsd_tbl` object.
#' @param n_modes Number of modal classes to return per sample.
#'
#' @return A tibble with exactly `n_modes` rows per sample and modal class
#'   descriptors. Samples with fewer observed modal classes are padded with
#'   `NA` descriptor fields and `mode_status = "not_observed"`.
#' @export
#'
#' @examples
#' gsd <- as_gsd_tbl(
#'   data.frame(
#'     sample = rep("A", 5),
#'     size_mm = c(2, 1, 0.5, 0.25, 0.125),
#'     retained = c(5, 35, 15, 30, 15)
#'   ),
#'   sample,
#'   size_mm,
#'   retained,
#'   value_type = "percent"
#' )
#'
#' gs_modes(gsd)
gs_modes <- function(x, n_modes = 3) {
  validate_gsd_tbl(x)
  if (!is.numeric(n_modes) || length(n_modes) != 1 || is.na(n_modes) || n_modes < 1) {
    stop("`n_modes` must be a positive whole number.", call. = FALSE)
  }
  n_modes <- as.integer(n_modes)

  split_data <- split(x, x$sample_id, drop = TRUE)
  modes <- lapply(split_data, modes_one_sample, n_modes = n_modes)
  out <- do.call(rbind, unname(modes))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
