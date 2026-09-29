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
| `lint` | `true` | Annotate chktex findings on the lines they refer to |
| `annotate_warnings` | `true` | Annotate warnings from the LaTeX log, such as undefined references and overfull boxes |
| `format_check` | `true` | Fail a separate `format` job when a file is not formatted with tex-fmt (the PDF is still published) |
| `tex_fmt_version` | `"0.5.7"` | tex-fmt release for `format_check`; keep it equal to the hook's `rev` |

After changing `root_file`, `engine` or `texlive_version`, run the workflow manually (Actions tab → Build LaTeX document → Run workflow) with **Update package list** ticked. See [AGENTS.md](AGENTS.md) for details, including how to move an existing Overleaf project over.

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
