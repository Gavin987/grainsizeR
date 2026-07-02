.format_accepted_values <- function(values) {
  paste(sprintf('"%s"', values), collapse = ", ")
}

.validate_choice <- function(value, choices, arg) {
  if (identical(value, "usda_tt") && "usda" %in% choices) {
    stop('`', arg, ' = "usda_tt"` has been replaced by `', arg, ' = "usda"` before v0.1.0.', call. = FALSE)
  }

  if (!is.character(value) || length(value) != 1 || is.na(value) || !value %in% choices) {
    stop(
      "`", arg, "` must be one of: ",
      .format_accepted_values(choices),
      ".",
      call. = FALSE
    )
  }
  value
}

.fraction_scheme_choices <- function() {
  unique(gs_fraction_schemes()$scheme)
}

.validate_fraction_scheme <- function(scheme, arg = "scheme") {
  .validate_choice(scheme, .fraction_scheme_choices(), arg)
}

.legacy_trigon_scheme_choices <- function() {
  c("gradistat", "usda", "isss", "uk_ssew")
}

.validate_legacy_trigon_scheme <- function(scheme, arg = "scheme") {
  .validate_choice(scheme, .legacy_trigon_scheme_choices(), arg)
}

.texture_rule_scheme_choices <- function() {
  c("usda", "gradistat")
}

.validate_texture_rule_scheme <- function(scheme, arg = "scheme") {
  .validate_choice(scheme, .texture_rule_scheme_choices(), arg)
}

.texture_ternary_scheme_choices <- function() {
  c("gradistat", "usda")
}

.validate_texture_ternary_scheme <- function(scheme, arg = "scheme") {
  .validate_choice(scheme, .texture_ternary_scheme_choices(), arg)
}

.validate_fraction_normalize_scheme <- function(scheme, normalize) {
  if (!identical(normalize, "fine_earth")) {
    return(invisible(TRUE))
  }

  components <- scheme_components(scheme)
  if (!"gravel" %in% components$component) {
    stop(
      '`normalize = "fine_earth"` requires a fraction scheme with a `gravel` component. ',
      "Use `normalize = \"none\"` or a gravel/sand/mud scheme such as `gravel_sand_mud`.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}
