# AGENTS.md

Template repository for a LaTeX document that GitHub Actions compiles to PDF on every push, publishing each build on `main` as a release. The build itself lives in [`atdr/latex-build`](https://github.com/atdr/latex-build), a reusable workflow; this repository only calls it.

## Layout

| Path | Purpose |
|---|---|
| `README.md` | User-facing overview: getting started, local builds, formatting |
| `main.tex` | The document (root file; set by `root_file`) |
| `.latexmkrc` | latexmk settings for local builds (XeLaTeX via `$pdf_mode = 5`); the workflow's `engine` overrides it |
| `texlive-packages.txt` | TeX Live packages to install (tlmgr names, `#` comments). Generated and committed by the workflow |
| `.pre-commit-config.yaml` | tex-fmt hook for `.tex`, `.cls` and `.sty` files (not `.bib`) |
| `.github/workflows/compile.yml` | Calls `atdr/latex-build` and holds the build settings |
| `.github/dependabot.yml` | Opens a PR for each new `atdr/latex-build` release |

## Settings

The settings are the inputs under `with` in `.github/workflows/compile.yml`. What each input does, and when the package list needs a manual run with "Update package list" ticked, is documented in [`atdr/latex-build`](https://github.com/atdr/latex-build) (README for callers, AGENTS.md for internals); link there rather than restating it here.

`tex_fmt_version` in `compile.yml` and the hook's `rev` in `.pre-commit-config.yaml` must name the same tex-fmt release, so the hook and CI agree.

## Adapting an Overleaf project

Copy `.github/` and `.pre-commit-config.yaml` into the project (and `.latexmkrc` only if it uses XeLaTeX and has none of its own), set the three settings from the project's Overleaf settings (Menu → Settings: compiler, TeX Live version, main document), and push. Imported sources are unlikely to be tex-fmt formatted, so either run `pre-commit run --all-files` once and commit the result, or set `format_check: false`.

## Updates

`compile.yml` calls `atdr/latex-build` at `@v1`, the Actions major-version convention, so 1.x releases apply here without a commit. Dependabot opens a PR for a new major version.

## Conventions

- **Single source of truth:** build behaviour is documented in `atdr/latex-build`. Link to it; do not restate it here, since `@v1` changes it without a commit in this repository.
- **Line length:** code (YAML, shell) wraps at 80 columns. Markdown is not hard-wrapped: one line per paragraph or list item.
- **Commits and PR titles:** use [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat: …`, `fix: …`, `docs: …`). The workflow's own list commits use `chore: update TeX Live package list`.
