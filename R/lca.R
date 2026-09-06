# R/lca.R
# Reusable helpers for latent class analysis via poLCA.
# Source this file from the analysis pipeline: source("R/lca.R")

# ---- fit_lca ---------------------------------------------------------------
#' Fit a sequence of LCA models with 1..max_k classes.
#'
#' @param data       data.frame of respondents.
#' @param indicators character vector of categorical indicator columns
#'                   (coded as integers starting at 1).
#' @param max_k      maximum number of classes to try.
#' @param nrep       number of random starts per model (stability).
#' @param weights    optional name of a sampling-weight column.
#' @return           list: models (per-k fit), indicators, max_k.
fit_lca <- function(data, indicators, max_k = 5, nrep = 10, weights = NULL) {
  check_pkg("poLCA")
  fml <- stats::as.formula(paste("cbind(",
          paste(indicators, collapse = ","), ") ~ 1"))

  fits <- lapply(1:max_k, function(k) {
    cat("Fitting LCA with", k, "class(es)...\n")
    poLCA::poLCA(
      fml,
      data       = data,
      nclass     = k,
      nrep       = nrep,
      probs.start = NULL,
      weights    = if (!is.null(weights)) data[[weights]] else NULL,
      verbose    = FALSE
    )
  })
  list(models = fits, indicators = indicators, max_k = max_k)
}

# ---- compare_classes -------------------------------------------------------
#' Tidy comparison table of the fitted LCA models.
#'
#' @param lca result of fit_lca().
#' @return     data.frame: K, ll, AIC, BIC, entropy, Gsq.
compare_classes <- function(lca) {
  tab <- lapply(lca$models, function(m) {
    data.frame(
      K       = m$nclass,
      ll      = round(m$llik, 2),
      AIC     = round(m$aic, 2),
      BIC     = round(m$bic, 2),
      Gsq     = round(m$Gsq, 2),
      entropy = round(entropy_lca(m), 3)
    )
  })
  do.call(rbind, tab)
}

# ---- entropy_lca -----------------------------------------------------------
#' Approximate entropy for a poLCA fit, in [0, 1].
#' Higher = clearer class separation.
entropy_lca <- function(m) {
  p <- m$P           # class prevalence probabilities
  pr <- m$probs     # list of class-conditional item probabilities
  H <- -sum(p * log(p), na.rm = TRUE)
  # Per-respondent classification entropy, averaged.
  if (!is.null(m$posterior)) {
    post <- m$posterior
    e <- -rowSums(post * log(post), na.rm = TRUE)
    E <- mean(e, na.rm = TRUE)
    k <- length(p)
    1 - E / log(k)
  } else {
    NA_real_
  }
}

# ---- plot_bic --------------------------------------------------------------
#' Plot BIC vs number of classes.
plot_bic <- function(lca, out_path = here::here("outputs", "figures", "lca-bic.png")) {
  tab <- compare_classes(lca)
  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
  grDevices::png(out_path, width = 1400, height = 900, res = 200)
  plot(tab$K, tab$BIC, type = "b", pch = 19,
       xlab = "Number of classes", ylab = "BIC",
       main = "LCA model comparison (BIC)")
  grDevices::dev.off()
  invisible(out_path)
}

# ---- assign_classes --------------------------------------------------------
#' Assign each respondent to its most likely class and return the data with
#' a new `class` column.
#'
#' @param lca  result of fit_lca().
#' @param data optional data.frame to attach the class to; if NULL uses the
#'             data stored in the model object.
assign_classes <- function(lca, data = NULL) {
  best <- best_model(lca)
  cls  <- apply(best$posterior, 1, which.max)
  if (is.null(data)) data <- best$y else data$class <- cls
  data$class <- factor(cls)
  data
}

# ---- class_profiles --------------------------------------------------------
#' Return item-response probabilities per class (rows = classes).
#'
#' @param lca result of fit_lca().
#' @return    list, one data.frame per indicator.
class_profiles <- function(lca) {
  best <- best_model(lca)
  lapply(seq_along(lca$indicators), function(i) {
      item <- lca$indicators[i]
      pr <- best$probs[[i]]
      df <- as.data.frame(pr)
      df$class <- seq_len(nrow(df))
      df$item <- item
      df[, c("class", "item", setdiff(names(df), c("class", "item")))]
    })
}

# ---- best_model (shared) --------------------------------------------------
best_model <- function(lca) {
  bics <- sapply(lca$models, function(m) m$bic)
  lca$models[[which.min(bics)]]
}

# ---- plot_profiles ---------------------------------------------------------
#' Tile plot of item-response probabilities per class.
plot_profiles <- function(lca, out_path = here::here("outputs", "figures", "lca-profiles.png")) {
  check_pkg("ggplot2")
  profs <- class_profiles(lca)
  df <- do.call(rbind, profs)
  # reshape to long
  df_long <- df %>%
    tidyr::pivot_longer(-c(class, item), names_to = "category", values_to = "prob")

  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
  grDevices::png(out_path, width = 1600, height = 1000, res = 200)
  p <- ggplot2::ggplot(df_long, ggplot2::aes(x = category, y = item, fill = prob)) +
    ggplot2::geom_tile() +
    ggplot2::facet_wrap(~ class) +
    ggplot2::scale_fill_gradient(low = "white", high = "#2a6f9b") +
    ggplot2::labs(title = "LCA class profiles", x = NULL, y = NULL) +
    ggplot2::theme_minimal()
  print(p)
  grDevices::dev.off()
  invisible(out_path)
}

# ---- check_pkg (shared) ----------------------------------------------------
check_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is not installed. Run renv::restore() or install.packages('", pkg, "').")
  }
}
