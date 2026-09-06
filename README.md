# Research Paper Template

A cloneable Quarto + R Markdown workspace for applied papers that combine **survey design**, **IPTW** (inverse probability of treatment weighting), **LCA** (latent class analysis), and **network analysis**, with a ready-to-fill reporting skeleton.

Each new paper starts from the same structure: copy the repo, rename the project, drop in data, and run the numbered analysis pipeline.

## What you get

- A **Quarto website guide** (this repo rendered to GitHub Pages) that walks coauthors through setup, each method, and the reporting skeleton.
- A **Quarto manuscript** (`paper/paper.qmd`) with standard sections and a reference manager wired in.
- Five reusable **R helper modules** (`R/`) plus a **numbered analysis pipeline** (`analysis/`) that reads raw data and emits reproducible outputs.
- A **renv** lockfile and a `targets`-friendly layout for reproducible results.

## Quickstart

```bash
# 1. Clone (or use the GitHub "Use this template" button)
gh repo create my-new-paper --template connectors-testing-pplx/research-paper-template
cd my-new-paper

# 2. Install R packages and restore the project library
Rscript -e "install.packages('renv'); renv::restore()"

# 3. Put your data in data/raw/ and edit analysis/00-config.R

# 4. Run the pipeline
Rscript analysis/run-all.R

# 5. Render the manuscript
quarto render paper/paper.qmd --to pdf

# 6. Render the guide site locally
quarto preview
```

## Repository layout

```
research-paper-template/
├── index.qmd              # Guide landing page
├── guide/                 # Handoff guide (rendered to GitHub Pages)
├── paper/                 # The manuscript (Quarto) + references.bib
├── R/                     # Reusable helper functions
│   ├── survey-design.R
│   ├── iptw.R
│   ├── lca.R
│   ├── network-analysis.R
│   └── reporting.R
├── analysis/             # Numbered pipeline: 00-config → 06-report
├── data/                 # raw/ (gitignored) + processed/
├── outputs/              # figures/ + tables/
├── .github/workflows/    # Renders the guide site on every push
├── renv.lock             # Pinned package versions
└── CITATION.cff
```

See the **live guide**: https://connectors-testing-pplx.github.io/research-paper-template/

## License

MIT for code; CC BY 4.0 for documentation. See `LICENSE`.
