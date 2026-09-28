#!/usr/bin/env bash
# Compiles ROOT_FILE with latexmk. When TeX cannot find a file, looks up the
# TeX Live package that provides it, reports it in the job summary and sets
# the step output missing_packages=true. Otherwise, as Overleaf does, treats
# a PDF produced despite errors (a BibTeX or xdvipdfmx warning, a LaTeX
# error that does not stop the PDF from being written) as success, setting
# the step output compiled_with_errors=true instead of failing the job.
set -uo pipefail

# latexmk writes its outputs to the working directory, even for a root file
# in a subdirectory
log="$(basename "$ROOT_FILE" .tex).log"
pdf="$(basename "$ROOT_FILE" .tex).pdf"
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
# Stop TeX wrapping log lines at 79 characters, so each error is on one line
export max_print_line=100000

# Files TeX reported as missing in the log (a font name without an extension
# comes from XeTeX/LuaTeX, which look fonts up by name)
missing_files() {
  sed -nE \
    -e "s/.*LaTeX Error: File \`([^']+)' not found.*/\\1/p" \
    -e "s/.*I can't find file \`([^']+)'.*/\\1/p" \
    -e 's/.*Font \\?[^= ]+=\[([^]]+)\].* not loadable.*/\1/p' \
    -e 's/.*Font \\?[^= ]+=([^ :"[]+) .* not loadable: Metric.*/\1.tfm/p' \
    "$log" 2>/dev/null | sort -u
}

# TeX Live package containing that file. The name may include a directory
# (foo/bar.sty) and may lack an extension (a font name from XeTeX/LuaTeX).
provider() {
  tlmgr search --global --file "/$1" 2>/dev/null | awk -v f="/$1" '
    function ends_with(s, t) {
      return length(s) >= length(t) && substr(s, length(s) - length(t) + 1) == t
    }
    /^[^ \t].*:$/ { pkg = substr($0, 1, length($0) - 1); next }
    {
      path = "/" $1
      bare = path; sub(/\.[^.\/]*$/, "", bare)
      if (ends_with(path, f) || ends_with(bare, f)) { print pkg; exit }
    }'
}

latexmk "$ENGINE" -file-line-error -interaction=nonstopmode "$ROOT_FILE" \
  && exit 0

files=$(missing_files)
if [ -n "$files" ]; then
  for file in $files; do
    package=$(provider "$file")
    if [ -n "$package" ]; then
      echo "::warning::$file is missing; it is in the TeX Live package $package"
      echo "\`$file\` is missing; it is in the TeX Live package" \
        "\`$package\`." >> "$summary"
      # Tells the workflow to regenerate texlive-packages.txt
      echo "missing_packages=true" >> "${GITHUB_OUTPUT:-/dev/null}"
    else
      echo "::error::No TeX Live package provides $file"
      echo "No TeX Live package provides \`$file\`." >> "$summary"
    fi
  done
  exit 1
fi

# latexmk failed, but not on a missing file, and still wrote a PDF (e.g. on a
# BibTeX "no citations" warning, an xdvipdfmx pdf_ref_obj error, or a LaTeX
# error that does not stop the PDF from being written). Overleaf ignores
# such errors as long as a PDF comes out, so publish this one too.
if [ -f "$pdf" ]; then
  echo "::warning::$ROOT_FILE compiled with errors; see the run-log artifact"
  echo "Compiled with errors; see the \`run-log\` artifact for details." \
    >> "$summary"
  echo "compiled_with_errors=true" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

exit 1
