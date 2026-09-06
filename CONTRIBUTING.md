# Contributing

This is a template repository. The best way to contribute is to use it for a paper and open an issue or pull request with improvements to the structure, helpers, or guide content.

## Style

- One job per `analysis/NN-*.R` script.
- Reusable logic in `R/`; orchestration in `analysis/`.
- Keep `data/raw/` untouched; write derivatives to `data/processed/`.
- Run `renv::snapshot()` after adding packages and commit `renv.lock`.
- Keep the guide (`guide/`) in sync with the helpers.

## Reporting issues

Open an issue at <https://github.com/connectors-testing-pplx/research-paper-template/issues>.
