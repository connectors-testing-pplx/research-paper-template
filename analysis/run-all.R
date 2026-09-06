# analysis/run-all.R
# Run the full numbered pipeline in order. Each script is self-contained:
# it sources 00-config.R, reads its inputs from disk, and writes its outputs.

options(tibble.print_min = 5)

scripts <- c(
  "01-import.R",
  "02-survey-design.R",
  "03-iptw.R",
  "04-lca.R",
  "05-network.R",
  "06-report.R"
)

for (s in scripts) {
  cat("\n==== Running", s, "====\n")
  source(file.path("analysis", s))
}
cat("\nAll pipeline steps complete.\n")
