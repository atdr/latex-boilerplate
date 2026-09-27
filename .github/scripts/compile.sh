#!/usr/bin/env bash
# Compiles ROOT_FILE with latexmk. When TeX cannot find a file, looks up the
# TeX Live package that provides it and reports it in the job summary.
set -uo pipefail

log="${ROOT_FILE%.tex}.log"
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

# TeX Live package containing that file (matching with or without extension)
provider() {
  tlmgr search --global --file "/$1" 2>/dev/null | awk -v f="$1" '
    /^[^ \t].*:$/ { pkg = substr($0, 1, length($0) - 1); next }
    {
      n = split($1, path, "/")
      if (path[n] == f || index(path[n], f ".") == 1) { print pkg; exit }
    }'
}

latexmk "$ENGINE" -file-line-error -interaction=nonstopmode "$ROOT_FILE" && exit 0

files=$(missing_files)
for file in $files; do
  package=$(provider "$file")
  if [ -n "$package" ]; then
    echo "::error::$file is missing; it is in the TeX Live package $package"
    echo "\`$file\` is missing; add \`$package\` to \`texlive-packages.txt\`." >> "$summary"
  else
    echo "::error::No TeX Live package provides $file"
    echo "No TeX Live package provides \`$file\`." >> "$summary"
  fi
done
if [ -n "$files" ]; then
  echo "TeX stops at the first missing file, so there may be more. To regenerate the whole list, run this workflow manually with \"Update package list\" ticked." >> "$summary"
fi
exit 1
