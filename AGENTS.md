# AGENTS.md

Boilerplate for a LaTeX document that GitHub Actions compiles to PDF on every
push. The workflow installs only the TeX Live packages the document needs, and
works out that list itself when needed.

## Layout

| Path | Purpose |
|---|---|
| `main.tex` | The document (root file; set by `ROOT_FILE`) |
| `.latexmkrc` | latexmk settings (XeLaTeX via `$pdf_mode = 5`) |
| `texlive-packages.txt` | TeX Live packages to install (tlmgr names, `#` comments). Generated; see below |
| `.github/workflows/compile.yml` | The build workflow and its settings |
| `.github/actions/setup-texlive/` | Local action: installs the listed packages from the selected TeX Live release |
| `.github/actions/publish-pdf/` | Local action: publishes the PDF (release on the default branch, run artifact elsewhere) |
| `.github/scripts/compile.sh` | Compiles; on failure, names the TeX Live package providing each missing file |
| `.github/scripts/list-packages.sh` | Runs in a full TeX Live image; rewrites `texlive-packages.txt` from what the build used |

## Settings

At the top of `compile.yml`, under `env`:

- `ROOT_FILE`: root `.tex` file.
- `ENGINE`: latexmk engine flag: `-pdf` (pdfLaTeX, Overleaf's default), `-xelatex` or `-lualatex`. latexmk command-line flags override `.latexmkrc`, so this setting decides the engine.
- `TEXLIVE_VERSION`: TeX Live release year (e.g. `2017`), or `latest`. Years before the current release install from the frozen `tlnet-final` archive on the Utah historic mirror.

A manual run (Actions tab → Build LaTeX document → Run workflow) takes two
optional inputs:

- **TeX Live version**: builds once with another release. Such a run never commits the package list.
- **Update package list**: regenerates `texlive-packages.txt` even if the build would pass.

## Build flow

Each push or manual run starts two jobs in sequence:

1. **`build_latex`** (about 10 s once the install is cached)
   - If `texlive-packages.txt` is missing or "Update package list" was
     ticked, it skips compiling and flags `update_packages`.
   - Otherwise it installs the listed packages (`zauguin/install-texlive`,
     cached per list and release) and compiles:
     - success: publishes the PDF;
     - a missing file that a TeX Live package provides: flags
       `update_packages`;
     - any other failure (LaTeX error, a missing file of the project's own):
       the job fails.
2. **`update_packages`** (only when flagged; about 2.5 min)
   - compiles in the full `texlive/texlive` image, where
     `list-packages.sh` rewrites `texlive-packages.txt`;
   - deletes that build's outputs, installs only the new list and compiles
     again, which verifies the list;
   - commits `texlive-packages.txt` if it changed (not on runs with another
     TeX Live version), then publishes the PDF.

- **Publishing:** on the repository's default branch the PDF is attached to a
  release tagged `build-<short SHA>`, which does not expire. Rebuilding the same
  commit replaces the PDF and updates the notes. On other branches the PDF is
  uploaded as the `pdf` artifact of the run, which expires under the artifact
  retention policy. When a build fails, its `.log` files are uploaded as the
  `run-log` artifact.
- **Failure messages:** when a file is missing, the job summary and annotations
  name the file and the package providing it (`tlmgr search --global --file`).
- **Workflow commits:** the list commit is made with `GITHUB_TOKEN`, so it
  does not trigger another run. The run that made it has already built and
  published the PDF with that list.

## How the package list is generated

`list-packages.sh` compiles in the full TeX Live image for the selected year,
then maps everything the build used to the TeX Live package that provides it,
using the image's `tlpkg/texlive.tlpdb`:

- files TeX read (`INPUT` lines of latexmk's `.fls` record);
- files found through kpathsea (`KPATHSEA_DEBUG=32`), which covers fonts XeTeX
  and xdvipdfmx load (these are not in the `.fls`), format builds and
  `kpsewhich` lookups;
- formats loaded (`execute AddFormat name=…` in the tlpdb);
- programs latexmk ran (its `Run number N of rule '…'` messages) and latexmk itself.

The list is rewritten from scratch, so unused packages are dropped as well as
missing ones added. It is tied to `TEXLIVE_VERSION`: package names and
dependencies differ between releases (e.g. TeX Live 2016 needs `lm` listed,
while later releases also need `l3kernel`).

## Changing things

- **Document changes:** just push. New packages are picked up automatically.
- **Changing `ENGINE`, `ROOT_FILE` or `TEXLIVE_VERSION`:** push, then run the
  workflow manually with "Update package list" ticked. The list is only
  regenerated automatically when a file is missing, not when a listed
  package becomes unused.
- **Editing `texlive-packages.txt` by hand:** fine; the next build checks it.
- **Adapting an Overleaf project:** copy `.github/` into the project (and
  `.latexmkrc` only if it uses XeLaTeX), set the three settings, and push.
  With no `texlive-packages.txt` present, the first run generates it. Overleaf
  stores the compiler and TeX Live version in project settings, not in Git.
- **Changing the workflow or scripts:** test in Actions, as there is no local
  equivalent of the runner. Check both the latest release and an old one
  (e.g. a manual run with TeX Live version `2016`), since installers, latexmk
  and log formats differ between years.

## Pitfalls

These already caused failures; keep them in mind when changing the scripts:

- **Historic installs over HTTPS:** older installers (e.g. 2016) cannot
  download over HTTPS, so historic repositories use `http://`. tlmgr still
  verifies the repository's signature (`(verified)` in the log).
- **Log parsing in `compile.sh`:** TeX wraps log lines at 79 characters;
  `compile.sh` sets `max_print_line` to stop this. With `-file-line-error`,
  errors start `./file.tex:N:` rather than `!`, and font errors lose the
  backslash before the font name, so patterns must accept both forms.
- **Hyphenation packages in the list:** the TeX Live 2016 image builds formats
  on first use, and that build reads every language's hyphenation patterns.
  `list-packages.sh` therefore compiles once untraced before recording.
- **Leftover files from the full build:** its outputs are owned by root, and
  latexmk could reuse its PDF, so `update_packages` changes their owner and
  runs `git clean` before verifying the new list.
- **Token exposure:** checkouts use `persist-credentials: false`, so the
  token is not on disk while TeX and the scripts run. Only the commit step
  (which pushes with `GH_TOKEN`) and the publish step receive it; keep new
  steps that way.
- **Failure handling in `build_latex`:** its compile step uses
  `continue-on-error` so that a missing package can hand over to
  `update_packages`. Any other failure is re-raised by the "Fail on other
  errors" step.
- **Missing programs:** a missing program (e.g. `biber`) is not a missing file,
  so it does not trigger regeneration; the manual "Update package list" run
  does pick it up.
- **Fonts outside TeX Live:** system fonts loaded by name through `fontspec`
  are not part of TeX Live and cannot be listed.
