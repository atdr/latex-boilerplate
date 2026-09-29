# LaTeX boilerplate

[![GitHub last commit](https://img.shields.io/github/last-commit/atdr/latex-boilerplate.svg?style=flat-square)](https://github.com/atdr/latex-boilerplate)
[![Build](https://img.shields.io/github/actions/workflow/status/atdr/latex-boilerplate/compile.yml?branch=main&style=flat-square&label=build)](https://github.com/atdr/latex-boilerplate/actions/workflows/compile.yml)

A starting point for a LaTeX document that GitHub Actions compiles to PDF on every push. The build runs in [`atdr/latex-build`](https://github.com/atdr/latex-build), a reusable workflow that installs only the TeX Live packages the document needs, at a TeX Live version you choose.

## Getting started

1. Click **Use this template** → **Create a new repository**.
2. Write your document in `main.tex`.
3. Push. The first build also generates and commits `texlive-packages.txt`, which lists the TeX Live packages to install.

## Settings and the build

The build settings are the inputs under `with` in `.github/workflows/compile.yml`. [`atdr/latex-build`'s README](https://github.com/atdr/latex-build#readme) documents each input, where the PDF is published, and [when to run with **Update package list** ticked](https://github.com/atdr/latex-build#the-package-list). To move an existing Overleaf project over, see [AGENTS.md](AGENTS.md#adapting-an-overleaf-project).

## Building locally

Install a TeX distribution ([TeX Live](https://tug.org/texlive/), or [MacTeX](https://tug.org/mactex/) on macOS), then run:

```sh
latexmk
```

`.latexmkrc` selects XeLaTeX. Your local TeX Live year may differ from the one CI uses (`texlive_version`), so treat the CI build as the reference.

## Formatting

The repository formats its LaTeX sources with [tex-fmt](https://github.com/WGUNDERWOOD/tex-fmt) through a [pre-commit](https://pre-commit.com) hook. Install pre-commit (`brew install pre-commit` or `pipx install pre-commit`), then once per clone:

```sh
pre-commit install
```

Each commit then formats the staged `.tex`, `.cls` and `.sty` files. If a file changes, the commit stops so you can review and stage the result. To format everything at once, run `pre-commit run --all-files`. The first run builds tex-fmt, which takes a minute; later runs are instant. Settings such as line length go in a `tex-fmt.toml` at the repository root.

`.bib` files are left alone, since they are usually exported from a reference manager and would be overwritten on the next export. If you maintain yours by hand, [bibtex-tidy](https://github.com/FlamingTempura/bibtex-tidy) formats, sorts and deduplicates BibTeX entries.

Commits made in Overleaf skip the hook. The hook only runs locally.

## License

[MIT](LICENSE)
