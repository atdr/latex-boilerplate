# LaTeX boilerplate

[![Build LaTeX document](https://github.com/atdr/latex-boilerplate/actions/workflows/compile.yml/badge.svg)](https://github.com/atdr/latex-boilerplate/actions/workflows/compile.yml)

A starting point for a LaTeX document that GitHub Actions compiles to PDF on every push. The build runs in [`atdr/latex-build`](https://github.com/atdr/latex-build), a reusable workflow that installs only the TeX Live packages the document needs, at a TeX Live version you choose.

## Getting started

1. Click **Use this template** → **Create a new repository**.
2. Write your document in `main.tex`.
3. Push. The first build generates and commits `texlive-packages.txt`.

## Where the PDF goes

- **On `main`:** each build is published as a release tagged `build-<short SHA>`, listed under Releases. Releases do not expire.
- **On other branches:** the PDF is attached to the workflow run as an artifact (Actions tab → the run → Artifacts).

## Settings

Set these under `with` in `.github/workflows/compile.yml`:

| Setting | Default | Meaning |
|---|---|---|
| `root_file` | `main.tex` | Root `.tex` file, relative to the repository root |
| `engine` | `-xelatex` | `-pdf` (pdfLaTeX), `-xelatex` or `-lualatex` |
| `texlive_version` | `latest` | TeX Live release year, e.g. `"2017"` |

After changing any of these, run the workflow manually (Actions tab → Build LaTeX document → Run workflow) with **Update package list** ticked. See [AGENTS.md](AGENTS.md) for details, including how to move an existing Overleaf project over.

## Building locally

Install a TeX distribution ([TeX Live](https://tug.org/texlive/), or [MacTeX](https://tug.org/mactex/) on macOS), then run:

```sh
latexmk
```

`.latexmkrc` selects XeLaTeX. Your local TeX Live year may differ from the one CI uses (`texlive_version`), so treat the CI build as the reference.

## License

[MIT](LICENSE)
