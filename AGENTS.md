# AGENTS.md

Template repository for a LaTeX document that GitHub Actions compiles to PDF on
every push, publishing each build on `main` as a release. The build itself lives
in [`atdr/latex-build`](https://github.com/atdr/latex-build), a reusable
workflow; this repository only calls it.

## Layout

| Path                                 | Purpose                                                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `README.md`                          | User-facing overview: getting started, local builds, formatting                                         |
| `main.tex`                           | The document (root file; set by `root_file`)                                                            |
| `.latexmkrc`                         | latexmk settings for local builds (XeLaTeX via `$pdf_mode = 5`); the workflow's `engine` overrides it   |
| `texlive-packages.txt`               | TeX Live packages to install (tlmgr names, `#` comments). Generated and committed by the workflow       |
| `.github/workflows/compile.yml`      | Calls `atdr/latex-build` and holds the build settings                                                   |
| `.github/workflows/checks.yml`       | Markdown and conventions checks, from `atdr/github-boilerplate`                                         |
| `.github/workflows/pull-request.yml` | Checks the PR title is a conventional commit                                                            |
| `.pre-commit-config.yaml`            | tex-fmt for `.tex`, `.cls` and `.sty` files (not `.bib`), Markdown checks, and the commit message check |
| `.github/dependabot.yml`             | Opens a PR for each new major `atdr/latex-build` release and each `atdr/github-boilerplate` release     |

## Settings

The settings are the inputs under `with` in `.github/workflows/compile.yml`.
What each input does, and when the package list needs a manual run with "Update
package list" ticked, is documented in
[`atdr/latex-build`](https://github.com/atdr/latex-build) (README for callers,
AGENTS.md for internals); link there rather than restating it here.

`tex_fmt_version` in `compile.yml` and the hook's `rev` in
`.pre-commit-config.yaml` must name the same tex-fmt release, so the hook and CI
agree.

## Adapting an Overleaf project

Run github-boilerplate's `scripts/apply.sh tex <project>`, which adds the
workflows and the rest of the GitHub setup, then copy `.latexmkrc` from here
only if the project uses XeLaTeX and has none of its own. Set the three settings
from the project's Overleaf settings (Menu → Settings: compiler, TeX Live
version, main document) and push. Imported sources are unlikely to be tex-fmt
formatted, so either run `pre-commit run --all-files` once and commit the
result, or set `format_check: false`.

## Where the GitHub setup comes from

Everything other than the document, `.latexmkrc` and `texlive-packages.txt`
(workflows, pre-commit, Dependabot, `.gitignore`, issue and PR templates, the
Markdown config) is the TeX overlay of
[`atdr/github-boilerplate`](https://github.com/atdr/github-boilerplate), copied
unedited. Change it there, not here, and check this copy with
`scripts/apply.sh tex <path> --diff` from a github-boilerplate clone.

## Updates

`compile.yml` calls `atdr/latex-build` at `@v1`, the Actions major-version
convention, so 1.x releases apply here without a commit. Dependabot opens a PR
for a new major version, and for each github-boilerplate release, whose
workflows are pinned to exact tags.

## Conventions

- **Single source of truth:** build behaviour is documented in
  `atdr/latex-build`. Link to it; do not restate it here, since `@v1` changes it
  without a commit in this repository.
- **Line length:** code (YAML, shell) and Markdown wrap at 80 columns. mdformat
  rewraps Markdown, and its pre-commit hook and the `checks` workflow enforce
  it.
- **Commits and PR titles:** use
  [Conventional Commits](https://www.conventionalcommits.org/) (e.g. `feat: …`,
  `fix: …`, `docs: …`). The workflow's own list commits use
  `chore: update TeX Live package list`.
