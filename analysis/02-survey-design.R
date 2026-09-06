# analysis/02-survey-design.R
# Build the survey design object and save it for downstream steps.

source("analysis/00-config.R")
source("R/survey-design.R")

analysis_df <- readRDS(file.path(processed_dir, "analysis.rds"))

design <- make_design(
  data   = analysis_df,
  ids    = design_vars$ids %||% "1",
  strata = design_vars$strata,
  weights= design_vars$weights,
  nest   = TRUE
)

summarise_weights(design)
saveRDS(design, file.path(processed_dir, "design.rds"))
message("Survey design saved to data/processed/design.rds")

`%||%` <- function(a, b) if (is.null(a)) b else a
