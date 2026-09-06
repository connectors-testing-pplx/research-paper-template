# analysis/01-import.R
# Load raw data from data/raw/ into memory, apply minimal cleaning, and
# write a processed copy to data/processed/analysis.rds.

source("analysis/00-config.R")

raw_path <- file.path(raw_dir, raw_file)
stopifnot(file.exists(raw_path))

# Use a robust reader: .csv via data.table, .rds via readRDS, .sav/.dta via haven.
read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  switch(ext,
    csv  = data.table::fread(path),
    rds  = readRDS(path),
    sav  = haven::read_sav(path),
    dta  = haven::read_dta(path),
    xlsx  = readxl::read_xlsx(path),
    stop("Unsupported file extension: ", ext)
  )
}

analysis_df <- read_any(raw_path)

# Minimal coercion: ensure character factors for design variables where useful.
for (v in unlist(design_vars)) {
  if (!is.null(v) && v %in% names(analysis_df) && is.character(analysis_df[[v]]))
    analysis_df[[v]] <- as.factor(analysis_df[[v]])
}

saveRDS(analysis_df, file.path(processed_dir, "analysis.rds"))
message("Imported ", nrow(analysis_df), " rows; wrote data/processed/analysis.rds")
