# AGENTS.md

Template repository for a LaTeX document that GitHub Actions compiles to PDF on every push, publishing each build on `main` as a release. The build itself lives in [`atdr/latex-build`](https://github.com/atdr/latex-build), a reusable workflow; this repository only calls it.

## Layout

| Path | Purpose |
|---|---|
| `main.tex` | The document (root file; set by `root_file`) |
| `.latexmkrc` | latexmk settings for local builds (XeLaTeX via `$pdf_mode = 5`); the workflow's `engine` overrides it |
| `texlive-packages.txt` | TeX Live packages to install (tlmgr names, `#` comments). Generated and committed by the workflow |
| `.github/workflows/compile.yml` | Calls `atdr/latex-build` and holds the build settings |
| `.github/dependabot.yml` | Opens a PR for each new `atdr/latex-build` release |

## Settings

In `.github/workflows/compile.yml`, under `with`:

- `root_file`: root `.tex` file, relative to the repository root (it may be in a subdirectory).
- `engine`: `-pdf` (pdfLaTeX, Overleaf's default), `-xelatex` or `-lualatex`.
- `texlive_version`: TeX Live release year as a string (e.g. `"2017"`), or `latest`.

After changing `engine`, `root_file` or `texlive_version`, run the workflow manually with "Update package list" ticked, since the list is only regenerated automatically when a file is missing.

A manual run (Actions tab → Build LaTeX document → Run workflow) can also build once with another TeX Live version; such a run never commits the package list.

## Adapting an Overleaf project

Copy `.github/` into the project (and `.latexmkrc` only if it uses XeLaTeX and has none of its own), set the three settings from the project's Overleaf settings (Menu → Settings: compiler, TeX Live version, main document), and push. With no `texlive-packages.txt` present, the first run generates and commits it.

## Updates

The workflow is pinned to an exact `atdr/latex-build` release (`@vX.Y.Z`). Dependabot opens a PR when a new one is out; the PR's build runs on its branch (the PDF is a run artifact there), and merging it publishes a release as usual. How the build works, its inputs and its pitfalls are documented in `atdr/latex-build`'s AGENTS.md.

## Conventions

- **Line length:** code (YAML, shell) wraps at 80 columns. Markdown is not hard-wrapped: one line per paragraph or list item.
- **Commits and PR titles:** use [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat: …`, `fix: …`, `docs: …`). The workflow's own list commits use `chore: update TeX Live package list`.
