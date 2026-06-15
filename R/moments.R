estimate_open_midpoints_phi <- function(sample_data) {
  sample_data <- sample_data[order(sample_data$bin_id), ]
  midpoint_phi <- sample_data$size_mid_phi
  boundary_phi <- um_to_phi(sample_data$raw_size_um)
  n <- nrow(sample_data)

  if (n < 3) {
    stop("At least three rows are required to estimate open-ended midpoints.", call. = FALSE)
  }

  coarse_width <- boundary_phi[2] - boundary_phi[1]
  fine_width <- boundary_phi[n - 1] - boundary_phi[n - 2]

  midpoint_phi[1] <- boundary_phi[1] - coarse_width / 2
  midpoint_phi[n] <- boundary_phi[n - 1] + fine_width / 2
  midpoint_phi
}

prepare_moment_sample <- function(sample_data, open_end) {
  sample_data <- sample_data[order(sample_data$bin_id), ]
  open_class <- sample_data$is_open_lower | sample_data$is_open_upper
  open_nonzero <- any(sample_data$retained_percent[open_class] > 0)

  if (open_end == "error" && open_nonzero) {
    stop(
      "Sample `",
      sample_data$sample_id[1],
      "` has nonzero retained percent in open-ended classes. Use ",
      "`open_end = \"extend_phi\"` or `open_end = \"omit\"` to calculate moments.",
      call. = FALSE
    )
  }

  if (open_end == "omit") {
    retained_percent_used <- sum(sample_data$retained_percent[!open_class])
    if (retained_percent_used <= 0) {
      stop("No retained percent remains after omitting open-ended classes.", call. = FALSE)
    }

    sample_data <- sample_data[!open_class, ]
    weights <- sample_data$retained_percent / retained_percent_used * 100

    return(list(
      sample_data = sample_data,
      midpoint_phi = sample_data$size_mid_phi,
      midpoint_um = sample_data$size_mid_um,
      weights = weights,
      retained_percent_used = retained_percent_used,
      open_end_estimated = FALSE,
      open_end_omitted = TRUE
    ))
  }

  midpoint_phi <- sample_data$size_mid_phi
  if (open_end == "extend_phi") {
    midpoint_phi <- estimate_open_midpoints_phi(sample_data)
  }

  list(
    sample_data = sample_data,
    midpoint_phi = midpoint_phi,
    midpoint_um = phi_to_um(midpoint_phi),
    weights = sample_data$retained_percent,
    retained_percent_used = sum(sample_data$retained_percent),
    open_end_estimated = open_end == "extend_phi",
    open_end_omitted = FALSE
  )
}

population_moments <- function(values, weights) {
  weights <- weights / sum(weights) * 100
  mean_value <- sum(weights * values) / 100
  sd_value <- sqrt(sum(weights * (values - mean_value)^2) / 100)

  if (sd_value == 0) {
    skewness <- NA_real_
    kurtosis <- NA_real_
  } else {
    skewness <- sum(weights * (values - mean_value)^3) / 100 / sd_value^3
    kurtosis <- sum(weights * (values - mean_value)^4) / 100 / sd_value^4
  }

  list(
    mean = mean_value,
    sd = sd_value,
    skewness = skewness,
    kurtosis = kurtosis
  )
}

moments_one_sample <- function(sample_data, method, open_end) {
  prepared <- prepare_moment_sample(sample_data, open_end)

  if (method == "logarithmic_phi") {
    values <- prepared$midpoint_phi
    moments <- population_moments(values, prepared$weights)
    mean_moment_unit <- "phi"
    sd_moment_unit <- "phi"
    mean_moment_phi <- moments$mean
    mean_moment_um <- phi_to_um(moments$mean)
  } else {
    values <- prepared$midpoint_um
    moments <- population_moments(values, prepared$weights)
    mean_moment_unit <- "um"
    sd_moment_unit <- "um"
    mean_moment_um <- moments$mean
    mean_moment_phi <- um_to_phi(moments$mean)
  }

  tibble::tibble(
    sample_id = sample_data$sample_id[1],
    moment_method = method,
    mean_moment = moments$mean,
    mean_moment_unit = mean_moment_unit,
    mean_moment_um = mean_moment_um,
    mean_moment_phi = mean_moment_phi,
    sd_moment = moments$sd,
    sd_moment_unit = sd_moment_unit,
    skewness_moment = moments$skewness,
    kurtosis_moment = moments$kurtosis,
    retained_percent_used = prepared$retained_percent_used,
    open_end = open_end,
    open_end_estimated = prepared$open_end_estimated,
    open_end_omitted = prepared$open_end_omitted
  )
}

#' Calculate grain-size moment statistics
#'
#' `gs_moments()` calculates population-style moments from grain-size class
#' midpoints. Logarithmic moments use phi midpoint values, while arithmetic
#' moments use micrometer midpoint values.
#'
#' @param x A valid `gsd_tbl` object.
#' @param method Moment scale. `"logarithmic_phi"` uses phi midpoints, and
#'   `"arithmetic_um"` uses micrometer midpoints.
#' @param open_end Handling for open-ended classes. `"error"` stops when
#'   open-ended classes contain retained material, `"extend_phi"` estimates
#'   open-ended midpoints by extending adjacent intervals in phi space, and
#'   `"omit"` drops open-ended classes and renormalizes the remaining retained
#'   percentages.
#'
#' @return A tibble with one row per sample and moment statistics.
#' @export
gs_moments <- function(x,
                       method = c("logarithmic_phi", "arithmetic_um"),
                       open_end = c("error", "extend_phi", "omit")) {
  validate_gsd_tbl(x)
  method <- match.arg(method)
  open_end <- match.arg(open_end)

  if (open_end == "extend_phi") {
    warning(
      "Open-ended class midpoints were estimated by extending adjacent phi intervals.",
      call. = FALSE
    )
  } else if (open_end == "omit") {
    warning(
      "Open-ended classes were omitted; returned moments describe a truncated distribution.",
      call. = FALSE
    )
  }

  split_data <- split(x, x$sample_id, drop = TRUE)
  out <- lapply(split_data, moments_one_sample, method = method, open_end = open_end)
  out <- do.call(rbind, unname(out))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
