# analysis/03-iptw.R
# Estimate propensity scores, construct IPTW weights, diagnose balance,
# and estimate the treatment effect.

source("analysis/00-config.R")
source("R/iptw.R")

analysis_df <- readRDS(file.path(processed_dir, "analysis.rds"))
design <- if (file.exists(file.path(processed_dir, "design.rds")))
            readRDS(file.path(processed_dir, "design.rds")) else NULL

iptw <- fit_iptw(
  data       = analysis_df,
  treatment  = iptw_vars$treatment,
  covariates = iptw_vars$covariates,
  method     = iptw_vars$method,
  estimand   = iptw_vars$estimand,
  design     = design
)

iptw <- trim_weights(iptw, at = 0.99)

bal <- check_balance(iptw, data = analysis_df, treatment = iptw_vars$treatment)
plot_balance(iptw, out_path = file.path(figures_dir, "iptw-balance.png"))

effect <- estimate_effect(
  iptw, data = analysis_df, outcome = outcome_var,
  family = get(outcome_family), design = design,
  cluster = design_vars$ids
)
print(effect)

saveRDS(iptw, file.path(processed_dir, "iptw.rds"))
write.csv(data.frame(estimate = effect$estimate, se = effect$se,
                     lower = effect$ci[1], upper = effect$ci[2]),
          file.path(tables_dir, "iptw-effects.csv"), row.names = FALSE)
message("IPTW done; effect = ", round(effect$estimate, 3))
