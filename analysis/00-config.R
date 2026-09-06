# analysis/00-config.R
# Project configuration. EDIT THIS FILE for each new paper.
# All paths, variable names, and options live here so the rest of the
# pipeline rarely needs touching.

# ---- Paths -----------------------------------------------------------------
proj_dir     <- normalizePath(here::here())
raw_dir      <- file.path(proj_dir, "data", "raw")
processed_dir<- file.path(proj_dir, "data", "processed")
out_dir      <- file.path(proj_dir, "outputs")
figures_dir  <- file.path(out_dir, "figures")
tables_dir   <- file.path(out_dir, "tables")

for (d in c(raw_dir, processed_dir, figures_dir, tables_dir))
  dir.create(d, showWarnings = FALSE, recursive = TRUE)

# ---- Reproducibility -------------------------------------------------------
set.seed(20260906)   # change per project, but keep it fixed

# ---- Project variables -----------------------------------------------------
# The file name of your raw survey data in data/raw/.
raw_file      <- "survey.csv"

# Survey design variables (set to NULL where not applicable).
design_vars <- list(
  ids    = "psu",       # cluster / PSU id
  strata = "stratum",
  weights= "wt"
)

# IPTW variables.
iptw_vars <- list(
  treatment   = "treated",
  covariates = c("age", "sex", "educ", "income", "region"),
  method     = "ps",
  estimand  = "ATE"
)

# LCA variables.
lca_vars <- list(
  indicators = c("item1", "item2", "item3", "item4", "item5"),
  max_k      = 5,
  nrep       = 10
)

# Network variables.
network_vars <- list(
  edge_file = "edges.csv",   # in data/raw/
  directed  = FALSE
)

# Outcome for the IPTW effect estimate.
outcome_var <- "y"
outcome_family <- "gaussian"   # or "binomial"

# ---- Packages --------------------------------------------------------------
pkgs <- c("here", "survey", "srvyr", "WeightIt", "cobalt", "poLCA",
          "igraph", "ggraph", "ggplot2", "tidyr", "dplyr", "purrr",
          "gt", "sandwich", "lmtest")
missing <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing)) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing)
}
invisible(lapply(pkgs, library, character.only = TRUE))

message("Config loaded. Project: ", basename(proj_dir))
