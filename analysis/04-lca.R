# analysis/04-lca.R
# Fit a sequence of LCA models, choose the best by BIC, assign classes,
# and write the class assignments and item-response profiles.

source("analysis/00-config.R")
source("R/lca.R")

analysis_df <- readRDS(file.path(processed_dir, "analysis.rds"))

lca <- fit_lca(
  data       = analysis_df,
  indicators = lca_vars$indicators,
  max_k      = lca_vars$max_k,
  nrep       = lca_vars$nrep,
  weights    = design_vars$weights
)

tab <- compare_classes(lca)
print(tab)
write.csv(tab, file.path(tables_dir, "lca-comparison.csv"), row.names = FALSE)
plot_bic(lca, out_path = file.path(figures_dir, "lca-bic.png"))

assigned <- assign_classes(lca, data = analysis_df)
saveRDS(assigned, file.path(processed_dir, "lca-classes.rds"))

profs <- class_profiles(lca)
prof_df <- do.call(rbind, profs)
write.csv(prof_df, file.path(tables_dir, "lca-profiles.csv"), row.names = FALSE)
plot_profiles(lca, out_path = file.path(figures_dir, "lca-profiles.png"))

message("LCA done; chose ", nlevels(assigned$class), " classes")
