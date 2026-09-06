# R/reporting.R
# Reusable helpers for turning pipeline results into manuscript-ready tables.
# Source this file from the analysis pipeline: source("R/reporting.R")

# ---- results_table ---------------------------------------------------------
#' Format a data frame as a gt table with sensible defaults.
#'
#' @param df     data.frame.
#' @param title  optional table caption.
#' @param group  optional column name to group rows by.
#' @return       gt object.
results_table <- function(df, title = NULL, group = NULL) {
  check_pkg("gt")
  tab <- gt::gt(df, groupname_col = group)
  if (!is.null(title)) tab <- gt::tab_header(tab, title = title)
  tab |>
    gt::opt_align_table_header(align = "left") |>
    gt::tab_options(table.font.size = gt::px(12))
}

# ---- forest_data -----------------------------------------------------------
#' Build a tidy data frame for a forest plot of subgroup treatment effects.
#'
#' @param effects named list, each element a numeric c(estimate, lower, upper)
#'                 for one subgroup.
#' @return         data.frame: subgroup, estimate, lower, upper.
forest_data <- function(effects) {
  do.call(rbind, lapply(names(effects), function(k) {
    v <- effects[[k]]
    data.frame(subgroup = k, estimate = v[1], lower = v[2], upper = v[3])
  }))
}

# ---- write_table -----------------------------------------------------------
#' Write a table to outputs/tables as both CSV and a gt HTML fragment.
#'
#' @param df       data.frame.
#' @param name     base filename (no extension).
#' @param tables_dir  directory for table outputs.
write_table <- function(df, name, tables_dir) {
  dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, file.path(tables_dir, paste0(name, ".csv")), row.names = FALSE)
  if (requireNamespace("gt", quietly = TRUE)) {
    html <- gt::as_raw_html(results_table(df))
    writeLines(html, file.path(tables_dir, paste0(name, ".html")))
  }
  invisible(file.path(tables_dir, paste0(name, ".csv")))
}

# ---- check_pkg (shared) ----------------------------------------------------
check_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is not installed. Run renv::restore() or install.packages('", pkg, "').")
  }
}
