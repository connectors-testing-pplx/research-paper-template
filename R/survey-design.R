# R/survey-design.R
# Reusable helpers for building and checking a complex-survey design object.
# Source this file from the analysis pipeline: source("R/survey-design.R")

# ---- make_design -----------------------------------------------------------
#' Build a survey design object from a data frame and design variables.
#'
#' @param data   data.frame of survey responses (one row per respondent).
#' @param ids    character. Name of the cluster/PSU id column, or "1" for no
#'               clustering.
#' @param strata  character. Name of the stratification column, or NULL.
#' @param weights character. Name of the sampling-weight column, or NULL.
#' @param nest   logical. Relabel ids within strata (recommended for most
#'               designs that come from survey organizations).
#' @return        A survey::svydesign object.
make_design <- function(data, ids = "1", strata = NULL, weights = NULL,
                         nest = TRUE) {
  check_pkg("survey")
  fml <- stats::as.formula(paste("~", ids))
  if (!is.null(strata))  fml <- stats::as.formula(paste("~", strata, "+", ids))
  if (!is.null(weights)) fml <- stats::as.formula(paste("~", weights))

  survey::svydesign(
    ids      = if (ids == "1") ~1 else stats::as.formula(paste("~", ids)),
    strata   = if (is.null(strata)) NULL else stats::as.formula(paste("~", strata)),
    weights  = if (is.null(weights)) NULL else stats::as.formula(paste("~", weights)),
    data     = data,
    nest     = nest
  )
}

# ---- calibrate_design ------------------------------------------------------
#' Post-stratify / calibrate a design to known population totals.
#'
#' @param design     svydesign object.
#' @param population named list of population proportions, e.g.
#'                   list(sex = c(M = 0.49, F = 0.51)).
#' @return           Calibrated svydesign.
calibrate_design <- function(design, population) {
  check_pkg("survey")
  totals <- unlist(lapply(names(population), function(v) {
    pop <- population[[v]]
    setNames(as.numeric(pop), paste0(v, names(pop)))
  }))
  survey::calibrate(design, formula = design$variables, population = totals)
}

# ---- summarise_weights -----------------------------------------------------
#' Print a quick summary of the design weights and effective sample size.
#'
#' @param design svydesign object.
#' @return       invisible data.frame with min, q25, median, q75, max, ESS.
summarise_weights <- function(design) {
  w <- stats::weights(design)
  ess <- (sum(w)^2) / sum(w^2)
  s <- as.data.frame(t(as.matrix(round(summary(w), 2))))
  s$ESS <- round(ess, 0)
  s$n_nominal <- length(w)
  print(s)
  invisible(s)
}

# ---- check_pkg (shared) ----------------------------------------------------
check_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is not installed. Run renv::restore() or install.packages('", pkg, "').")
  }
}
