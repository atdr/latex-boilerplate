# AGENTS.md

Template repository for a LaTeX document that GitHub Actions compiles to PDF on every push, publishing each build on `main` as a release. The build itself lives in [`atdr/latex-build`](https://github.com/atdr/latex-build), a reusable workflow; this repository only calls it.

## Layout

| Path | Purpose |
|---|---|
| `README.md` | User-facing overview: getting started, where PDFs go, local builds |
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
- `lint` and `annotate_warnings`: report chktex findings (on their file and line) and warnings from the final LaTeX log (on the run) as annotations and in the job summary. They never fail the build.
- `format_check` and `tex_fmt_version`: a separate `format` job fails when a `.tex`, `.cls` or `.sty` file is not formatted with tex-fmt; the PDF is still published. Keep `tex_fmt_version` equal to the `rev` of the hook in `.pre-commit-config.yaml` (without the `v`).

After changing `engine`, `root_file` or `texlive_version`, run the workflow manually with "Update package list" ticked, since the list is only regenerated automatically when a file is missing.

A manual run (Actions tab → Build LaTeX document → Run workflow) can also build once with another TeX Live version; such a run never commits the package list.

## Adapting an Overleaf project

Copy `.github/` into the project (and `.latexmkrc` only if it uses XeLaTeX and has none of its own), set the three settings from the project's Overleaf settings (Menu → Settings: compiler, TeX Live version, main document), and push. Imported sources are unlikely to be tex-fmt formatted, so either run `pre-commit run --all-files` once and commit the result, or set `format_check: false`. With no `texlive-packages.txt` present, the first run generates and commits it.

## Updates

The workflow uses `atdr/latex-build@v1`, which follows every 1.x release, so fixes arrive without a change here. Dependabot opens a PR when a new major version (with breaking changes) is out; the PR's build runs on its branch (the PDF is a run artifact there), and merging it publishes a release as usual. To freeze a document's build, pin an exact release (`@v1.2.3`) instead. How the build works, its inputs and its pitfalls are documented in `atdr/latex-build`'s AGENTS.md.

## Conventions

- **Line length:** code (YAML, shell) wraps at 80 columns. Markdown is not hard-wrapped: one line per paragraph or list item.
- **Commits and PR titles:** use [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat: …`, `fix: …`, `docs: …`). The workflow's own list commits use `chore: update TeX Live package list`.
