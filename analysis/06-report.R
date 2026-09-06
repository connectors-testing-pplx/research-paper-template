# analysis/06-report.R
# Assemble manuscript-ready tables from the pipeline outputs.

source("analysis/00-config.R")
source("R/reporting.R")

analysis_df <- readRDS(file.path(processed_dir, "analysis.rds"))

# ---- Descriptive table -----------------------------------------------------
desc <- analysis_df %>%
  dplyr::summarise(
    n = dplyr::n(),
    age_mean = round(mean(.data[[iptw_vars$covariates[1]]], na.rm = TRUE), 1),
    pct_treated = round(100 * mean(.data[[iptw_vars$treatment]], na.rm = TRUE), 1)
  )
write_table(desc, "descriptive", tables_dir)

# ---- LCA comparison --------------------------------------------------------
if (file.exists(file.path(tables_dir, "lca-comparison.csv"))) {
  lca_tab <- utils::read.csv(file.path(tables_dir, "lca-comparison.csv"))
  write_table(lca_tab, "lca-comparison", tables_dir)
}

# ---- Network summary -------------------------------------------------------
if (file.exists(file.path(tables_dir, "network-summary.csv"))) {
  net_tab <- utils::read.csv(file.path(tables_dir, "network-summary.csv"))
  write_table(net_tab, "network-summary", tables_dir)
}

message("Reporting tables written to outputs/tables/")
