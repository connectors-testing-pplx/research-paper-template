# R/iptw.R
# Reusable helpers for inverse-probability-of-treatment weighting.
# Wraps WeightIt (weight construction) and cobalt (balance diagnostics).
# Source this file from the analysis pipeline: source("R/iptw.R")

# ---- fit_iptw --------------------------------------------------------------
#' Estimate propensity scores and construct IPTW weights.
#'
#' @param data        data.frame of analysis units.
#' @param treatment   character. Name of the binary treatment column.
#' @param covariates  character vector of confounder column names.
#' @param method       passed to WeightIt::weightit (e.g. "ps", "gbm", "cbps").
#' @param estimand    "ATE" (default), "ATT", or "ATC".
#' @param design      optional survey::svydesign; when supplied, the propensity
#'                    model is weighted by sampling weights.
#' @return            list with elements: weights, model (the weightit object),
#'                    treatment, covariates.
fit_iptw <- function(data, treatment, covariates, method = "ps",
                     estimand = "ATE", design = NULL) {
  check_pkg("WeightIt")
  fml <- stats::as.formula(paste(treatment, "~", paste(covariates, collapse = " + ")))
  s.weights <- if (!is.null(design)) stats::weights(design) else NULL

  w_obj <- WeightIt::weightit(
    fml,
    data       = data,
    method     = method,
    estimand   = estimand,
    s.weights  = s.weights
  )
  list(weights = w_obj$weights, model = w_obj,
       treatment = treatment, covariates = covariates, estimand = estimand)
}

# ---- check_balance ---------------------------------------------------------
#' Compute covariate balance before and after weighting.
#'
#' @param iptw      result of fit_iptw().
#' @param data      data.frame used in fit_iptw().
#' @param treatment name of the treatment column.
#' @return          cobalt::bal.tab object (printed).
check_balance <- function(iptw, data, treatment) {
  check_pkg("cobalt")
  bal <- cobalt::bal.tab(
    iptw$model,
    data = data,
    un = TRUE,
    imbalanced.only = FALSE
  )
  print(bal)
  invisible(bal)
}

# ---- plot_balance ----------------------------------------------------------
#' Render a love plot of standardized mean differences.
#'
#' @param iptw      result of fit_iptw().
#' @param out_path  file path to save the PNG.
plot_balance <- function(iptw, out_path = here::here("outputs", "figures", "iptw-balance.png")) {
  check_pkg("cobalt")
  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
  grDevices::png(out_path, width = 1600, height = 1000, res = 200)
  cobalt::love.plot(iptw$model, threshold = 0.1,
                    title = "Covariate balance (SMD)")
  grDevices::dev.off()
  invisible(out_path)
}

# ---- trim_weights ----------------------------------------------------------
#' Trim IPTW weights at a given quantile to limit variance.
#'
#' @param iptw result of fit_iptw().
#' @param at   upper quantile at which to trim (default 0.99).
#' @return     iptw list with trimmed weights.
trim_weights <- function(iptw, at = 0.99) {
  cap <- stats::quantile(iptw$weights, probs = at, na.rm = TRUE)
  iptw$weights <- pmin(iptw$weights, cap)
  iptw
}

# ---- estimate_effect -------------------------------------------------------
#' Estimate the (weighted) treatment effect on an outcome.
#'
#' @param iptw     result of fit_iptw().
#' @param data     data.frame with the outcome and cluster columns.
#' @param outcome  name of the outcome column.
#' @param family   glm family (gaussian, binomial, ...).
#' @param design   optional survey design; if provided, uses design-based SEs
#'                 with the combined (sampling * IPTW) weight.
#' @param cluster  optional name of cluster column for cluster-robust SEs.
#' @return         list with estimate, SE, CI, and the fitted model.
estimate_effect <- function(iptw, data, outcome, family = stats::gaussian,
                            design = NULL, cluster = NULL) {
  data$.iptw_w <- iptw$weights
  fml <- stats::as.formula(paste(outcome, "~", iptw$treatment))

  if (!is.null(design)) {
    # Combine sampling and IPTW weights multiplicatively.
    check_pkg("survey")
    w <- stats::weights(design) * data$.iptw_w
    d2 <- survey::svydesign(ids = ~1, weights = ~w, data = data)
    fit <- survey::svyglm(fml, design = d2, family = family)
    est <- stats::coef(fit)[2]
    se  <- sqrt(stats::vcov(fit)[2, 2])
  } else {
    fit <- stats::glm(fml, data = data, family = family, weights = .iptw_w)
    if (!is.null(cluster)) {
      check_pkg("sandwich"); check_pkg("lmtest")
      vc <- sandwich::vcovCL(fit, cluster = data[[cluster]])
      est <- stats::coef(fit)[2]
      se  <- sqrt(vc[2, 2])
    } else {
      est <- stats::coef(fit)[2]
      se  <- sqrt(stats::vcov(fit)[2, 2])
    }
  }
  ci <- est + c(-1.96, 1.96) * se
  list(estimate = est, se = se, ci = ci, model = fit)
}

# ---- check_pkg (shared) ----------------------------------------------------
check_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is not installed. Run renv::restore() or install.packages('", pkg, "').")
  }
}
